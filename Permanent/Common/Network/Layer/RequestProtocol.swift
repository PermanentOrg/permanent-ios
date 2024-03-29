//
//  RequestProtocol.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

/// The request type that matches the URLSessionTask types.
enum RequestType {
    /// Will translate to a URLSessionDataTask.
    case data
    /// Will translate to a URLSessionDownloadTask.
    case download
    /// Will translate to a URLSessionUploadTask.
    case upload
}

/// The expected remote response type.
enum ResponseType {
    case json
    case file
}

/// HTTP request methods.
enum RequestMethod: String {
    case get = "GET"
    case post
    case put
    case patch
    case delete
}

typealias RequestHeaders = [String: String]
typealias RequestParameters = Any
typealias ProgressHandler = (Float) -> Void

/// Protocol to which the HTTP requests must conform.
protocol RequestProtocol {
    /// The path that will be appended to API's base URL.
    var path: String { get }

    /// The HTTP method.
    var method: RequestMethod { get }

    /// The HTTP headers.
    var headers: RequestHeaders? { get }

    /// The request parameters used for query parameters for GET requests and in the HTTP body for POST, PUT and PATCH requests.
    var parameters: RequestParameters? { get }

    /// The request type.
    var requestType: RequestType { get }

    /// The expected response type.
    var responseType: ResponseType { get }

    /// Upload/download progress handler.
    var progressHandler: ProgressHandler? { get set }
    
    var bodyData: Data? { get }
    
    var customURL: String? { get }
}

extension RequestProtocol {
    // Creates a URLRequest from this instance.
    /// - Parameter environment: The environment against which the `URLRequest` must be constructed.
    /// - Returns: An optional `URLRequest`.
    public func urlRequest(with environment: EnvironmentProtocol) -> URLRequest? {
        var request: URLRequest
        
        // If we have a custom URL, we just use it as is.
        if let stringURL = customURL,
            let url = URL(string: stringURL) {
            request = URLRequest(url: url)
        } else if let url = url(with: environment.baseURL) {
            request = URLRequest(url: url)
        } else {
            return nil
        }

        // Append all related properties.
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = bodyData ?? jsonBody
        
        return request
    }

    private func url(with baseURL: String) -> URL? {
        // Create a URLComponents instance to compose the url.
        guard var urlComponents = URLComponents(string: baseURL) else {
            return nil
        }
        // Add the request path to the existing base URL path
        urlComponents.path += path
        // Add query items to the request URL if needed
        if queryItems != nil {
            urlComponents.queryItems = queryItems
        }
        
        return urlComponents.url
    }

    /// Returns the URLRequest `URLQueryItem`
    private var queryItems: [URLQueryItem]? {
        // Chek if it is a GET method.
        guard method == .get, let parameters = parameters as? [String: Any?] else {
            return nil
        }
        // Convert parameters to query items.
        return parameters.map { (key: String, value: Any?) -> URLQueryItem in
            let valueString = String(describing: value)
            return URLQueryItem(name: key, value: valueString)
        }
    }

    /// Returns the URLRequest body `Data`
    private var jsonBody: Data? {
        // The body data should be used for POST, PUT and PATCH only
        guard
            [.post, .put, .patch].contains(method),
            let parameters = parameters else {
            return nil
        }
        // Convert parameters to JSON data
        var jsonBody: Data?
        do {
            jsonBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print(error)
        }
        return jsonBody
    }
    
    var headers: RequestHeaders? {
        if method == .post {
            return ["content-type": "application/json; charset=utf-8"]
        } else {
            return nil
        }
    }
}
