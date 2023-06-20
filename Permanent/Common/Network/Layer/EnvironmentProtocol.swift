//
//  EnvironmentProtocol.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

/// Protocol to which environments must conform.
protocol EnvironmentProtocol {
    /// The default HTTP request headers for the environment.
    var headers: RequestHeaders? { get }
    
    /// The base URL of the environment.
    var baseURL: String { get }
}
