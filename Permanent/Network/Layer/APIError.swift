//
//  APIError.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

/// Enum of API Errors
enum APIError: Error, Equatable {
    /// No data received from the server.
    case noData
    /// The server response was invalid (unexpected format).
    case invalidResponse
    /// The request was rejected: 400-499
    case badRequest(String?)
    /// Encoutered a server error.
    case serverError(String?)
    /// There was an error parsing the data.
    case parseError(String?)
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
