//
//  APIEnvironment.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

enum APIEnvironment: EnvironmentProtocol {
    case staging
    case development
    case production
    
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
