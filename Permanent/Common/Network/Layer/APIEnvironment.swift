//
//  APIEnvironment.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

enum APIEnvironment: String, EnvironmentProtocol {
    case staging
    case development = "dev"
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
    
    var apiServer: String {
        switch self {
        case .staging:
            return "https://api.staging.permanent.org/"
        case .development:
            return "https://dev.permanent.org/"
        case .production:
            return "https://api.permanent.org/"
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
    
    var donationBaseURL: String {
        switch self {
        case .staging:
            return "https://us-central1-prpledgestaging.cloudfunctions.net/donation"
        case .development:
            return "https://us-central1-prpledgedev.cloudfunctions.net/donation"
        case .production:
            return "https://us-central1-prpledgeprod.cloudfunctions.net/donation"
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
    
    var authorizationURL: String {
        switch self {
        case .staging:
            return "https://permanent-dev.fusionauth.io/oauth2/authorize"
        case .development:
            return "https://permanent-dev.fusionauth.io/oauth2/authorize"
        case .production:
            return "https://auth.permanent.org/oauth2/authorize"
        }
    }
    
    var tokenURL: String {
        switch self {
        case .staging:
            return "https://permanent-dev.fusionauth.io/oauth2/token"
        case .development:
            return "https://permanent-dev.fusionauth.io/oauth2/token"
        case .production:
            return "https://auth.permanent.org/oauth2/token"
        }
    }
    
    /// The base Fusion Auth URL of the given environment.
    var fusionBaseURL: String {
        switch self {
        case .staging:
            return "https://permanent-dev.fusionauth.io/api"
        case .development:
            return "https://permanent-dev.fusionauth.io/api"
        case .production:
            return "https://permanent.fusionauth.io/api"
        }
    }
    
    var rolesMatrix: String {
        return "https://permanent.zohodesk.com/portal/en/kb/articles/roles-for-collaboration-and-sharing"
    }
    
    #if STAGING_ENVIRONMENT
    static let defaultEnv: APIEnvironment = .staging
    #else
    static let defaultEnv: APIEnvironment = .production
    #endif
}
