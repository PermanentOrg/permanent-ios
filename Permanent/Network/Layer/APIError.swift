//
//  APIError.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

/// Enum of API Errors
enum APIError: Error {
    /// No data received from the server.
    case noData
    /// The server response was invalid (unexpected format).
    case invalidResponse
    /// The request was rejected: 400
    case badRequest
    /// The request was rejected: 401
    case unauthorized
    /// The request was rejected: 403
    case forbidden
    /// The request was rejected: 40x that is not handled by the above
    case clientError
    /// Encoutered a server error.
    case serverError
    /// There was an error parsing the data.
    case parseError
    /// Unknown error.
    case unknown
    /// Request cancelled.
    case cancelled
    
    static func error(withCode code: Int?) -> APIError? {
        switch code {
        case NSURLErrorCancelled:
            return .cancelled
            
        default:
            return nil
        }
    }
    
    var message: String {
        switch self {
        case .cancelled: return .errorCancelled
        case .unknown: return .errorUnknown
        default: return .errorServer
        }
    }
}
