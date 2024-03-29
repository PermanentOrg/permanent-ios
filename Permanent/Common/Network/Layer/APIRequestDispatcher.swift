//
//  APIRequestDispatcher.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

class APIRequestDispatcher: RequestDispatcherProtocol {
    static let sessionExpiredNotificationName = Notification.Name("APIRequestDispatcher.sessionExpiredNotificationName")
    
    var ignoresMFAWarning = false
    
    /// The environment configuration.
    private var environment: EnvironmentProtocol

    /// The network session configuration.
    private var networkSession: NetworkSessionProtocol

    /// Required initializer.
    /// - Parameters:
    ///   - environment: Instance conforming to `EnvironmentProtocol` used to determine on which environment the requests will be executed.
    ///   - networkSession: Instance conforming to `NetworkSessionProtocol` used for executing requests with a specific configuration.
    required init(
        environment: EnvironmentProtocol = APIEnvironment.defaultEnv,
        networkSession: NetworkSessionProtocol = APINetworkSession()
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
        
        if let token = PermSession.currentSession?.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        NetworkLogger.log(request: urlRequest)
        
        // Create a URLSessionTask to execute the URLRequest.
        var task: URLSessionTask?
        switch request.requestType {
        case .data:
            task = networkSession.dataTask(with: urlRequest, completionHandler: { data, urlResponse, error in
                self.handleJsonTaskResponse(data: data, urlResponse: urlResponse, error: error, completion: completion)
            })
            
        case .upload:
            task = networkSession.uploadTask(with: urlRequest, progressHandler: request.progressHandler, completion: { data, urlResponse, error in
                self.handleJsonTaskResponse(data: data, urlResponse: urlResponse, error: error, completion: completion)
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
    ///   - completion: Completion handler.
    private func handleJsonTaskResponse(data: Data?, urlResponse: URLResponse?, error: Error?, completion: @escaping (OperationResult) -> Void) {
        // Check for errors
        if let apiError = APIError.error(withCode: (error as NSError?)?.code) {
            return completion(.error(apiError, nil))
        }

        // Check if the response is valid.
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            completion(OperationResult.error(APIError.invalidResponse, nil))
            return
        }
        NetworkLogger.log(response: urlResponse, data: data, error: error)
        
        // Verify the HTTP status code.
        let result = verify(data: data, urlResponse: urlResponse, error: error)
        switch result {
        case .success(let data):
            // Parse the JSON data
            let parseResult = parse(data: data as? Data)
            switch parseResult {
            case .success(let json):
                if let mfaError = json as? [String: Any],
                let results = mfaError["Results"] as? [[String: Any]],
                let message = (results[0]["message"] as? [String])?.first,
                (message == "warning.auth.mfaToken" && !ignoresMFAWarning) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Self.sessionExpiredNotificationName, object: self)
                    }
                } else {
                    completion(OperationResult.json(json, urlResponse))
                }
                
            case .failure(let error):
                completion(OperationResult.error(error, urlResponse))
            }
            
        case .failure(let error):
            if error as? APIError == APIError.unauthorized {
                completion(OperationResult.error(error, urlResponse))
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.sessionExpiredNotificationName, object: self)
                }
            } else {
                completion(OperationResult.error(error, urlResponse))
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
}
