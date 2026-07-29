//
//  APIRequestDispatcher.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation
import os.log

class APIRequestDispatcher: RequestDispatcherProtocol {
    static let sessionExpiredNotificationName = Notification.Name("APIRequestDispatcher.sessionExpiredNotificationName")
    private let authLogger = Logger(subsystem: "com.permanent.ios", category: "UploadFlow")
    
    var ignoresMFAWarning = false
    
    /// The environment configuration.
    private var environment: EnvironmentProtocol

    /// The network session configuration.
    private var networkSession: NetworkSessionProtocol

    #if DEBUG
    /// True when this process is hosting an XCTest **unit** bundle.
    ///
    /// The unit suite must never reach the network. It used to: a full run issued ~255 live
    /// requests to staging, whose 401s posted `sessionExpiredNotificationName` and produced 714
    /// asynchronous `logout()` calls — nulling `AuthenticationManager.shared.session` at random
    /// points, so any test reading session-backed state could fail on timing alone. Three CI
    /// failures came from that. It also meant the suite could mutate real staging data
    /// (`/api/account/update`, `/api/archive/change`) whenever it ran with a valid token.
    ///
    /// `XCTestConfigurationFilePath` is set by XCTest in the process the test bundle is injected
    /// into. Unit tests run inside the app host, so it is present. UI tests drive a separate app
    /// process that is NOT given it, so `PermanentUITests` keeps its real networking — which also
    /// means this needs no test-plan wiring and cannot be missed when a plan is added.
    /// Read once; the environment is fixed for the process lifetime.
    private static let isHostingUnitTests =
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    #endif

    /// The session handed to dispatchers that don't specify one. Production code constructs
    /// `APIRequestDispatcher()` at hundreds of call sites, so this default is the only practical
    /// chokepoint for keeping the unit suite offline. Tests that want canned responses keep
    /// injecting their own seam or passing `networkSession:` explicitly, and are unaffected.
    static func defaultNetworkSession() -> NetworkSessionProtocol {
        #if DEBUG
        if isHostingUnitTests { return OfflineTestNetworkSession() }
        #endif
        return APINetworkSession()
    }

    /// As `defaultNetworkSession()`, for the CDN-backed download path. Separate factory because
    /// `CDNSession` carries its own configuration; the point is that the offline substitution
    /// happens here too, so no call site can quietly bypass it.
    static func defaultCDNSession() -> NetworkSessionProtocol {
        #if DEBUG
        if isHostingUnitTests { return OfflineTestNetworkSession() }
        #endif
        return CDNSession()
    }

    /// Required initializer.
    /// - Parameters:
    ///   - environment: Instance conforming to `EnvironmentProtocol` used to determine on which environment the requests will be executed.
    ///   - networkSession: Instance conforming to `NetworkSessionProtocol` used for executing requests with a specific configuration.
    required init(
        environment: EnvironmentProtocol = APIEnvironment.defaultEnv,
        networkSession: NetworkSessionProtocol = APIRequestDispatcher.defaultNetworkSession()
    ) {
        self.environment = environment
        self.networkSession = networkSession
    }
    
    /// Executes a request.
    /// - Parameters:
    ///   - request: Instance conforming to `RequestProtocol`
    ///   - completion: Completion handler.
    func execute(request: RequestProtocol, createdTask: @escaping (URLSessionTask?) -> Void, completion: @escaping (OperationResult) -> Void) {
        // Create a URL request.
        guard var urlRequest = request.urlRequest(with: environment) else {
            completion(.error(APIError.badRequest, nil))
            createdTask(nil)
            return
        }
        
        // Add the environment specific headers.
        environment.headers?.forEach { (key: String, value: String) in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        if let cookies = HTTPCookieStorage.shared.cookies(for: urlRequest.url!) {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
            
            cookieHeaders.forEach { (key: String, value: String) in
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if !request.skipAuthentication {
            if let token = PermSession.currentSession?.token {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                // The Bearer token is missing. Server falls back to cookie auth,
                // which on the Permanent API requires a CSRF token that we don't
                // send — so the request will fail with `error.generic.invalid_csrf`.
                // Track this loudly to find when/why `currentSession.token` got nil.
                let path = urlRequest.url?.path ?? "<no path>"
                let hasSession = PermSession.currentSession != nil
                let cookieCount = HTTPCookieStorage.shared.cookies(for: urlRequest.url!)?.count ?? 0
                authLogger.error("🔼 [AUTH] No Bearer token for \(path, privacy: .public) — hasSession=\(hasSession, privacy: .public) cookies=\(cookieCount, privacy: .public)")
            }
        }
        
        // Share token header for V2 folder endpoints
        if let shareToken = request.shareToken {
            urlRequest.setValue(shareToken, forHTTPHeaderField: "X-Permanent-Share-Token")
        }
        
        NetworkLogger.log(request: urlRequest)
        
        let shouldIgnoreErrors = request.ignoreErrors
        
        // Create a URLSessionTask to execute the URLRequest.
        var task: URLSessionTask?
        switch request.requestType {
        case .data:
            task = networkSession.dataTask(with: urlRequest, completionHandler: { data, urlResponse, error in
                self.handleJsonTaskResponse(data: data, urlResponse: urlResponse, error: error, ignoreErrors: shouldIgnoreErrors, completion: completion)
            })
            
        case .upload:
            task = networkSession.uploadTask(with: urlRequest, progressHandler: request.progressHandler, completion: { data, urlResponse, error in
                self.handleJsonTaskResponse(data: data, urlResponse: urlResponse, error: error, ignoreErrors: shouldIgnoreErrors, completion: completion)
            })
            
        case .download:
            guard
                let parameters = request.parameters as? [String: Any?],
                let fileName = parameters["filename"] as? String
            else {
                completion(.error(APIError.badRequest, nil))
                createdTask(nil)
                return
            }
            
            task = networkSession.downloadTask(with: urlRequest, fileName: fileName, progressHandler: request.progressHandler, completion: { fileUrl, urlResponse, error in
                self.handleFileTaskResponse(fileUrl: fileUrl, urlResponse: urlResponse, error: error, completion: completion)
            })
        }
        // Start the task.
        task?.resume()
        
        createdTask(task)
    }

    /// Handles the data response that is expected as a JSON object output.
    /// - Parameters:
    ///   - data: The `Data` instance to be serialized into a JSON object.
    ///   - urlResponse: The received  optional `URLResponse` instance.
    ///   - error: The received  optional `Error` instance.
    ///   - ignoreErrors: If true, errors will be silently ignored without triggering session expiration
    ///   - completion: Completion handler.
    private func handleJsonTaskResponse(data: Data?, urlResponse: URLResponse?, error: Error?, ignoreErrors: Bool, completion: @escaping (OperationResult) -> Void) {
        // This runs on URLSession's background delegate queue (APINetworkSession no longer hops
        // to main), so the JSON `parse` below is OFF the main thread — a large listing no longer
        // blocks the UI while it's serialized. Deliver every result back on main via this shim so
        // callers keep their completion-on-main guarantee no matter who invoked the dispatcher.
        let deliver: (OperationResult) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        // Check for errors
        if let apiError = APIError.error(withCode: (error as NSError?)?.code) {
            return deliver(.error(apiError, nil))
        }

        // Preserve URLError so callers can detect transient connectivity issues
        // (network dropped during Wi-Fi/cellular handoff, etc.) and retry without
        // burning a retry attempt. Without this, all network errors get reduced
        // to APIError.invalidResponse and the upload pipeline can't tell them
        // apart from real server-side bugs.
        if let urlError = error as? URLError {
            authLogger.debug("🔼 [NETWORK] URLError code=\(urlError.code.rawValue, privacy: .public) for \(urlResponse?.url?.path ?? "<no path>", privacy: .public)")
            return deliver(.error(urlError, urlResponse as? HTTPURLResponse))
        }

        // Check if the response is valid.
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            deliver(OperationResult.error(APIError.invalidResponse, nil))
            return
        }
        NetworkLogger.log(response: urlResponse, data: data, error: error)

        let shouldIgnoreAuthErrors = ignoreErrors || isNonCriticalEndpoint(urlResponse)

        // Verify the HTTP status code.
        let result = verify(data: data, urlResponse: urlResponse, error: error)
        switch result {
        case .success(let data):
            // Parse the JSON data (off the main thread — see the note above).
            let parseResult = parse(data: data as? Data)
            switch parseResult {
            case .success(let json):
                if let mfaError = json as? [String: Any],
                let results = mfaError["Results"] as? [[String: Any]],
                let message = (results[0]["message"] as? [String])?.first,
                (message == "warning.auth.mfaToken" && !ignoresMFAWarning && !shouldIgnoreAuthErrors) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Self.sessionExpiredNotificationName, object: self)
                    }
                    // The caller's completion must still fire: dropping it left
                    // spinners waiting forever and leaked any continuation bridged
                    // to this callback. Deliver it as an auth error.
                    deliver(OperationResult.error(APIError.unauthorized, urlResponse))
                } else {
                    deliver(OperationResult.json(json, urlResponse))
                }

            case .failure(let error):
                deliver(OperationResult.error(error, urlResponse))
            }

        case .failure(let error):
            if error as? APIError == APIError.unauthorized && !shouldIgnoreAuthErrors {
                let failPath = urlResponse.url?.path ?? "<no path>"
                authLogger.error("🔼 [AUTH] 401 from \(failPath, privacy: .public) — posting sessionExpired (will trigger logout)")
                deliver(OperationResult.error(error, urlResponse))

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.sessionExpiredNotificationName, object: self)
                }
            } else {
                deliver(OperationResult.error(error, urlResponse))
            }
        }
    }
    
    /// Handles the url response that is expected as a file saved ad the given URL.
    /// - Parameters:
    ///   - fileUrl: The `URL` where the file has been downloaded.
    ///   - urlResponse: The received  optional `URLResponse` instance.
    ///   - error: The received  optional `Error` instance.
    ///   - completion: Completion handler.
    private func handleFileTaskResponse(fileUrl: URL?, urlResponse: URLResponse?, error: Error?, completion: @escaping (OperationResult) -> Void) {
        // Check for errors
        if let apiError = APIError.error(withCode: (error as NSError?)?.code) {
            return completion(.error(apiError, nil))
        }
        
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            completion(OperationResult.error(APIError.invalidResponse, nil))
            return
        }
        
        let result = verify(data: fileUrl, urlResponse: urlResponse, error: error)
        switch result {
        case .success(let url):
            DispatchQueue.main.async {
                completion(OperationResult.file(url as? URL, urlResponse))
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                completion(OperationResult.error(error, urlResponse))
            }
        }
    }

    /// Parses a `Data` object into a JSON object.
    /// - Parameter data: `Data` instance to be parsed.
    /// - Returns: A `Result` instance.
    private func parse(data: Data?) -> Result<Any?, Error> {
        guard let data = data, !data.isEmpty else {
            return .success(nil)
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return .success(json)
        } catch {
            let stringResponse = String(decoding: data, as: UTF8.self)
            if stringResponse.isNotEmpty {
                return .success(stringResponse)
            }
            return .failure(APIError.invalidResponse)
        }
    }

    /// Checks if the HTTP status code is valid and returns an error otherwise.
    /// - Parameters:
    ///   - data: The data or file  URL .
    ///   - urlResponse: The received  optional `URLResponse` instance.
    ///   - error: The received  optional `Error` instance.
    /// - Returns: A `Result` instance.
    private func verify(data: Any?, urlResponse: HTTPURLResponse, error: Error?) -> Result<Any, Error> {
        switch urlResponse.statusCode {
        case 200...299:
            return .success(data as Any)
            
        case 400:
            return .failure(APIError.badRequest)
            
        case 401:
            return .failure(APIError.unauthorized)
            
        case 403:
            return .failure(APIError.forbidden)
            
        case 400...499:
            return .failure(APIError.clientError)
            
        case 500...599:
            return .failure(APIError.serverError)
            
        default:
            return .failure(APIError.unknown)
        }
    }
    
    private func checkForError(_ error: Error?) -> APIError? {
        guard let errorCode = (error as NSError?)?.code else { return nil }
        
        switch errorCode {
        case NSURLErrorCancelled:
            return .cancelled
            
        default: return nil
        }
    }
    
    private func isNonCriticalEndpoint(_ urlResponse: HTTPURLResponse) -> Bool {
        guard let url = urlResponse.url?.absoluteString else { return false }
        
        if url.contains("/api/v2/event") && !url.contains("/checklist") {
            return true
        }
        
        if url.contains("/api/v2/share-links") {
            return true
        }

        // Stela V2 endpoints opt out of the 401 force-logout per-case via
        // `RequestProtocol.ignoreErrors` (see RecordV2Endpoint/FolderV2Endpoint) rather
        // than growing this URL list: reads are exempt (foreign-item 401s are expected,
        // V1 failsafes surface genuine expiry), writes keep the expiry signal.
        return false
    }
}
