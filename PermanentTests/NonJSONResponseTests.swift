//
//  NonJSONResponseTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 22.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// During an outage the server, or a proxy in front of it, answers with a web page and status 200.
/// That body must become the normal server error, never a crash inside `JSONSerialization`.
@Suite
struct NonJSONResponseTests {
    private static let htmlPage = "<!DOCTYPE html><html><body>Down</body></html>"

    private struct Flag: Codable {
        let isSuccessful: Bool
    }

    // MARK: - JSONHelper

    @Test("decoding returns nil for a web page instead of crashing")
    func decodingRefusesHTML() {
        let model: Flag? = JSONHelper.decoding(from: Self.htmlPage, with: JSONDecoder())
        #expect(model == nil)
    }

    @Test("convertToModel returns nil for a web page instead of crashing")
    func convertToModelRefusesHTML() {
        let model: Flag? = JSONHelper.convertToModel(from: Self.htmlPage)
        #expect(model == nil)
    }

    @Test("decoding still decodes a dictionary")
    func decodingAcceptsDictionary() {
        let model: Flag? = JSONHelper.decoding(from: ["isSuccessful": true], with: JSONDecoder())
        #expect(model?.isSuccessful == true)
    }

    @Test("convertToModel still decodes an array")
    func convertToModelAcceptsArray() {
        let models: [Flag]? = JSONHelper.convertToModel(from: [["isSuccessful": true], ["isSuccessful": false]])
        #expect(models?.map(\.isSuccessful) == [true, false])
    }

    // MARK: - APIRequestDispatcher

    @Test("A 200 with a web page body becomes the server error, with the response attached")
    func dispatcherTurnsHTMLIntoInvalidResponse() async throws {
        let session = CannedSession(body: Data(Self.htmlPage.utf8), contentType: "text/html")
        let result = try await changeArchiveResult(through: session)

        guard case .error(let error, let response) = result else {
            Issue.record("expected .error, got \(result)")
            return
        }
        #expect(error as? APIError == .invalidResponse)
        #expect(response?.statusCode == 200)
    }

    @Test("An empty 200 body still arrives as json(nil)")
    func dispatcherKeepsEmptyBody() async throws {
        let session = CannedSession(body: Data(), contentType: "application/json")
        let result = try await changeArchiveResult(through: session)

        guard case .json(let json, let response) = result else {
            Issue.record("expected .json, got \(result)")
            return
        }
        #expect(json == nil)
        #expect(response?.statusCode == 200)
    }

    @Test("A JSON 200 body still arrives as a dictionary")
    func dispatcherKeepsJSONBody() async throws {
        let session = CannedSession(body: Data(#"{"isSuccessful":true}"#.utf8), contentType: "application/json")
        let result = try await changeArchiveResult(through: session)

        guard case .json(let json, _) = result else {
            Issue.record("expected .json, got \(result)")
            return
        }
        #expect((json as? [String: Any])?["isSuccessful"] as? Bool == true)
    }

    // MARK: - Helpers

    /// Answers every data task with status 200, the given body and `Content-Type`, from a background
    /// queue as the real session does.
    private final class CannedSession: NetworkSessionProtocol {
        private let body: Data
        private let contentType: String

        init(body: Data, contentType: String) {
            self.body = body
            self.contentType = contentType
        }

        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
            guard let url = request.url else {
                completionHandler(nil, nil, URLError(.badURL))
                return nil
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": contentType])
            DispatchQueue.global(qos: .userInitiated).async {
                completionHandler(self.body, response, nil)
            }
            return nil
        }

        func uploadTask(with request: URLRequest, progressHandler: ProgressHandler?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask? { nil }

        func downloadTask(with request: URLRequest, fileName: String, progressHandler: ProgressHandler?, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? { nil }
    }

    private struct TimedOut: Error {}

    /// Lets the first of the completion and the timeout resume the continuation, never both.
    private final class Once {
        private let lock = NSLock()
        private var claimed = false

        func claim() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if claimed { return false }
            claimed = true
            return true
        }
    }

    /// Sends the launch request, `/archive/change`, through a dispatcher on the given session and
    /// waits for its result. Fails after a few seconds instead of hanging on a slow machine.
    private func changeArchiveResult(through session: NetworkSessionProtocol) async throws -> OperationResult {
        let dispatcher = APIRequestDispatcher(networkSession: session)
        let request = ArchivesEndpoint.change(archiveId: 1, archiveNbr: "0001-0000")
        let once = Once()

        return try await withCheckedThrowingContinuation { continuation in
            let timeout = DispatchSource.makeTimerSource(queue: .global())
            timeout.schedule(deadline: .now() + .seconds(5))
            timeout.setEventHandler {
                if once.claim() { continuation.resume(throwing: TimedOut()) }
            }
            timeout.resume()
            dispatcher.execute(request: request, createdTask: { _ in }) { result in
                timeout.cancel()
                if once.claim() { continuation.resume(returning: result) }
            }
        }
    }
}
