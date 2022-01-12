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
    
    var buyStorageURL: String {
        switch self {
        case .staging:
            return "https://staging.permanent.org/add-storage/"
        case .development:
            return "https://dev.permanent.org/add-storage/"
        case .production:
            return "https://www.permanent.org/add-storage/"
        }
    }
    
    var helpURL: String {
        return "https://desk.zoho.com/portal/permanent/en/home"
    }
    
    var publicURL: String {
        switch self {
        case .staging:
            return "https://staging.permanent.org/p"
        case .development:
            return "https://dev.permanent.org/p"
        case .production:
            return "https://www.permanent.org/p"
        }
    }
    
    #if STAGING_ENVIRONMENT
    static let defaultEnv: APIEnvironment = .staging
    #else
    static let defaultEnv: APIEnvironment = .production
    #endif
}
