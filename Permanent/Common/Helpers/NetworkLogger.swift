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

        /// Maximum number of body bytes rendered. Bodies are stringified on the dispatcher's
        /// completion thread (currently main), so this is not unbounded — a multi-megabyte
        /// listing would stall the UI just to be logged. 1 MB is far above any real API
        /// response here (the largest, a full folder listing, is tens of KB) while still
        /// bounding the pathological case. Staging only: `environmentRestriction` keeps all
        /// of this out of production, and `logBodies` is off there regardless.
        var maxBodyLength: Int = 1_000_000

        /// Bytes per emitted log line. os_log truncates an individual message well before
        /// `maxBodyLength` — in practice around 1 KB — so a long body must be emitted in
        /// pieces or the tail is silently lost (this is what hid the archive list: the cut
        /// happened at ~1 KB even though the cap was 10 KB and no truncation marker was
        /// appended, because the loss was in os_log, not here).
        var logChunkSize: Int = 800
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
    
    /// Enable verbose network logging (all levels, request/response bodies included).
    /// For internal/staging builds only — bodies are stringified on the dispatcher's
    /// completion thread and may contain user data, so production must not use this.
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

    /// Renders a body for logging, capped at `maxBodyLength` bytes so a large payload
    /// never pays a full stringify (this runs on the dispatcher's completion thread —
    /// currently main). A truncated or non-UTF-8 body degrades to replacement
    /// characters instead of silently dropping the log line.
    static func loggableBody(_ body: Data) -> String {
        let cap = configuration.maxBodyLength
        guard body.count > cap else { return String(decoding: body, as: UTF8.self) }
        return String(decoding: body.prefix(cap), as: UTF8.self) + " … [truncated \(body.count - cap) of \(body.count) bytes]"
    }

    /// Emits a body across as many log lines as it takes, because os_log drops the tail of
    /// any single long message. Each line is prefixed `label [i/n]` so `log stream` output
    /// can be reassembled in order; a short body still logs as one unprefixed line.
    private static func logBody(_ label: String, _ body: Data) {
        let text = loggableBody(body)
        let size = max(1, configuration.logChunkSize)
        guard text.count > size else {
            logger.debug("\(label): \(text, privacy: .public)")
            return
        }
        let chars = Array(text)
        let total = (chars.count + size - 1) / size
        for index in 0..<total {
            let start = index * size
            let piece = String(chars[start..<min(start + size, chars.count)])
            logger.debug("\(label) [\(index + 1, privacy: .public)/\(total, privacy: .public)]: \(piece, privacy: .public)")
        }
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

