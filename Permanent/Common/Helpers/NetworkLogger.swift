//
//  NetworkLogger.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.01.2022.
//

import Foundation
import os.log

class NetworkLogger {
    
    /// Enum to define different logging levels
    enum LogLevel: Int {
        case none = 0    // No logging
        case error = 1   // Only errors
        case info = 2    // Errors and basic info
        case debug = 3   // All logs including detailed debug info
        
        var osLogType: OSLogType {
            switch self {
            case .none: return .default
            case .error: return .error
            case .info: return .info
            case .debug: return .debug
            }
        }
    }
    
    /// Configuration struct to control logging behavior
    struct Configuration {
        /// Whether logging is enabled at all
        var isEnabled: Bool = true
        
        /// Only log in specific environments (e.g., staging)
        var environmentRestriction: APIEnvironment? = .staging
        
        /// Current log level
        var logLevel: LogLevel = .debug
        
        /// Whether to log request/response bodies
        var logBodies: Bool = true

        /// Cap on rendered body bytes: stringifying happens on the dispatcher's completion thread, so an
        /// unbounded body would stall the UI just to be logged. Far above any real response here.
        var maxBodyLength: Int = 1_000_000
    }
    
    /// Current logger configuration
    static var configuration = Configuration()
    
    /// Logger for network requests and responses
    private static let logger = Logger(subsystem: "com.permanent.ios", category: "NetworkRequests")
    
    /// Shorthand to check if logging is currently enabled
    private static var isLoggingEnabled: Bool {
        guard configuration.isEnabled else { return false }
        
        if let restrictedEnv = configuration.environmentRestriction {
            return APIEnvironment.defaultEnv == restrictedEnv
        }
        
        return true
    }
    
    /// Completely disable all network logging
    static func disableLogging() {
        configuration.isEnabled = false
    }
    
    /// Verbose logging, bodies included. Internal builds only: bodies stringify on the dispatcher's
    /// completion thread and may contain user data.
    static func enableLogging() {
        NetworkLogger.configuration.logLevel = .debug
        NetworkLogger.configuration.environmentRestriction = nil // Log in all environments
        NetworkLogger.configuration.logBodies = true
        configuration.isEnabled = true
    }

    /// Production logging: errors only, never bodies. Keeps os_log diagnostics for
    /// failed requests without paying any per-response body-stringify cost.
    static func enableErrorLogging() {
        NetworkLogger.configuration.logLevel = .error
        NetworkLogger.configuration.environmentRestriction = nil
        NetworkLogger.configuration.logBodies = false
        configuration.isEnabled = true
    }
    
    /// Set the current log level
    static func setLogLevel(_ level: LogLevel) {
        configuration.logLevel = level
    }
    
    /// Log a network request
    static func log(request: URLRequest) {
        guard isLoggingEnabled, configuration.logLevel.rawValue >= LogLevel.info.rawValue else { return }
        
        let urlAsString = request.url?.absoluteString ?? ""
        let urlComponents = URLComponents(string: urlAsString)
        let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
        let path = "\(urlComponents?.path ?? "")"
        let query = "\(urlComponents?.query ?? "")"
        let host = "\(urlComponents?.host ?? "")"
        
        logger.log(level: configuration.logLevel.osLogType, "📤 OUTGOING REQUEST: \(urlAsString, privacy: .public)")
        logger.log(level: configuration.logLevel.osLogType, "Method: \(method, privacy: .public) Path: \(path, privacy: .public)?Query: \(query, privacy: .public)")
        logger.log(level: configuration.logLevel.osLogType, "Host: \(host, privacy: .public)")
        
        // Log headers if debug level
        if configuration.logLevel == .debug {
            var headersString = ""
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                headersString += "\(key): \(value) | "
            }
            if !headersString.isEmpty {
                logger.debug("Headers: \(headersString, privacy: .public)")
            }
        }
        
        // Log body if present and enabled
        if configuration.logBodies, configuration.logLevel == .debug, let body = request.httpBody {
            logBody("Body", body)
        }
    }

    /// Renders a body for logging, capped at `maxBodyLength` so a large payload never pays a full
    /// stringify. Truncated or non-UTF-8 bytes degrade to replacement characters, not a dropped line.
    static func loggableBody(_ body: Data) -> String {
        let cap = configuration.maxBodyLength
        guard body.count > cap else { return String(decoding: body, as: UTF8.self) }
        return String(decoding: body.prefix(cap), as: UTF8.self) + " … [truncated \(body.count - cap) of \(body.count) bytes]"
    }

    /// One unbroken line via stdout, because os_log truncates a message near 1 KB and drops the tail
    /// silently. Not visible to `log stream` as a result — read bodies in Xcode's console.
    private static func logBody(_ label: String, _ body: Data) {
        print("\(label): \(loggableBody(body))")
    }
    
    /// Log a network response
    static func log(response: HTTPURLResponse?, data: Data?, error: Error?) {
        // Always log errors regardless of log level
        if let error = error, configuration.isEnabled, configuration.logLevel.rawValue >= LogLevel.error.rawValue {
            logger.error("❌ NETWORK ERROR: \(error.localizedDescription, privacy: .public)")
            return
        }
        
        guard isLoggingEnabled, configuration.logLevel.rawValue >= LogLevel.info.rawValue else { return }
        
        let urlString = response?.url?.absoluteString ?? "No URL"
        let components = NSURLComponents(string: urlString)
        let path = components?.path ?? ""
        let query = components?.query ?? ""
        let statusCode = response?.statusCode ?? 0
        
        logger.log(level: configuration.logLevel.osLogType, "📥 INCOMING RESPONSE: \(urlString, privacy: .public)")
        logger.log(level: configuration.logLevel.osLogType, "Status: \(statusCode, privacy: .public) Path: \(path, privacy: .public)?Query: \(query, privacy: .public)")
        
        // Log headers if debug level
        if configuration.logLevel == .debug {
            var headersString = ""
            for (key, value) in response?.allHeaderFields ?? [:] {
                headersString += "\(key): \(value) | "
            }
            if !headersString.isEmpty {
                logger.debug("Headers: \(headersString, privacy: .public)")
            }
        }
        
        // Log body if present and enabled
        if configuration.logBodies, configuration.logLevel == .debug, let body = data {
            logBody("Body", body)
        }
    }
}

