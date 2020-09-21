//
//  APIError.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

/// Enum of API Errors
enum APIError: Error {
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
}
