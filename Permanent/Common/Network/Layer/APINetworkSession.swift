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
/// Network session used by the unit suite: every task fails immediately with
/// `URLError(.notConnectedToInternet)` and no `URLResponse`.
///
/// Chosen deliberately over returning a canned HTTP response. In
/// `APIRequestDispatcher.handleJsonTaskResponse` a `URLError` is delivered before `verify()` is
/// ever reached, so no HTTP status code is produced, `APIError.unauthorized` can never be
/// synthesized, and the 401 → `sessionExpiredNotificationName` → `logout()` path is unreachable
/// from tests. Completions still fire exactly once, on main, so nothing hangs.
///
/// A test that needs a real response injects its own seam (`childrenFetchV2Request`,
/// `relocateV1Request`, a repository double, …) or passes `networkSession:` explicitly — neither
/// goes through this type.
final class OfflineTestNetworkSession: NetworkSessionProtocol {
    private static let offline = URLError(.notConnectedToInternet)

    /// A real request is never instantaneous, and several tests legitimately observe in-flight
    /// state (`isLoadingArchives`, "renders while searching") between kicking a request off and
    /// its completion. Completing inline would collapse that window to nothing and break them for
    /// the wrong reason. This is small enough to be free — nothing waits on it that did not
    /// already wait on a much slower real request — and, unlike network latency, it is constant.
    /// 150ms is chosen against the two constraints actually present in the suite: tests that
    /// observe in-flight state sleep up to 100ms before asserting it (e.g.
    /// ShareFindArchiveByEmailViewTests.testRendersWhileSearching), while tests that wait for
    /// completion either use a publisher/expectation with a 1-3s timeout or sleep 200ms. So the
    /// window is (100ms, 200ms) and this sits in the middle of it.
    private static let latency: DispatchTimeInterval = .milliseconds(150)

    private func complete(_ work: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Self.latency, execute: work)
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        complete { completionHandler(nil, nil, Self.offline) }
        return nil
    }

    // Upload and download deliberately mirror the REAL `APINetworkSession` rather than reporting
    // `offline`: that session already refuses both inline with this same error and never touches
    // the network, so substituting a URLError here would be a behaviour change, not isolation.
    // It would also be a harmful one — `UploadManager.isTransientNetworkError` treats
    // `.notConnectedToInternet` as transient and exempts it from the retry cap, so an upload
    // failure would become infinitely retryable under test while staying capped in production.
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
        // Deliver the raw response on URLSession's background delegate queue — do NOT hop to
        // main here. The dispatcher's JSON parse (JSONSerialization) then runs off the main
        // thread, so a large folder/record listing no longer blocks the UI while it's decoded.
        // APIRequestDispatcher re-dispatches the finished OperationResult to main, so callers
        // still receive their completion on the main thread.
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
