//
//  APINetworkSession.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

class APINetworkSession: NSObject {
    /// The URLSession handing the URLSessionTaks.
    var session: URLSession!

    override public convenience init() {
        self.init(configuration: nil)
    }

    public init(configuration: URLSessionConfiguration?) {
        super.init()
        if let configuration = configuration {
            self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        } else {
            self.session = URLSession.shared
        }
    }
}

#if DEBUG
/// The unit suite's session: every task fails with `URLError(.notConnectedToInternet)` and no
/// response, so no status code exists and the 401 force-logout path is unreachable from tests.
final class OfflineTestNetworkSession: NetworkSessionProtocol {
    private static let offline = URLError(.notConnectedToInternet)

    /// Completing inline would collapse the in-flight window that several tests observe, so keep a
    /// small constant delay. It sits between the 100ms those tests wait and the 200ms others allow.
    private static let latency: DispatchTimeInterval = .milliseconds(150)

    private func complete(_ work: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Self.latency, execute: work)
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        complete { completionHandler(nil, nil, Self.offline) }
        return nil
    }

    // Upload and download mirror the real session rather than reporting offline: it already refuses
    // both inline. A `URLError` here would read as transient and become infinitely retryable.
    private static let unsupported = NSError(domain: "org.permanent", code: 1000, userInfo: nil)

    func uploadTask(with request: URLRequest, progressHandler: ProgressHandler?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask? {
        completion(nil, nil, Self.unsupported)
        return nil
    }

    func downloadTask(with request: URLRequest, fileName: String, progressHandler: ProgressHandler?, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {
        completion(nil, nil, Self.unsupported)
        return nil
    }
}
#endif

extension APINetworkSession: NetworkSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        // Deliver on URLSession's delegate queue, never hopping to main, so the dispatcher's JSON parse
        // runs off-main. The dispatcher re-dispatches the finished result, so callers still get main.
        let dataTask = session.dataTask(with: request) { data, response, error in
            completionHandler(data, response, error)
        }

        return dataTask
    }

    func uploadTask(with request: URLRequest, progressHandler: ProgressHandler?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask? {
        completion(nil, nil, NSError(domain: "org.permanent", code: 1000, userInfo: nil))
        return nil
    }

    func downloadTask(with request: URLRequest, fileName: String, progressHandler: ProgressHandler?, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {
        completion(nil, nil, NSError(domain: "org.permanent", code: 1000, userInfo: nil))
        return nil
    }
}
