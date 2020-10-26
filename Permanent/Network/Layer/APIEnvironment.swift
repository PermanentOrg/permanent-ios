//
//  APIEnvironment.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

enum APIEnvironment: EnvironmentProtocol {
    case staging
    case development
    case production
    
    /// The default HTTP request headers for the given environment.
    var headers: RequestHeaders? {
        switch self {
        case .staging:
            return [:]
        case .development:
            return [:]
        case .production:
            return [:]
        }
    }
    
    /// The base URL of the given environment.
    var baseURL: String {
        switch self {
        case .staging:
            return "https://staging.permanent.org/api"
        case .development:
            return "https://dev.permanent.org/api"
        case .production:
            return "https://www.permanent.org/api"
        }
    }
}
