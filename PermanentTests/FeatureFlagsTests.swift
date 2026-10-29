//
//  FeatureFlagsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The server's switches: a listed name is on, an unlisted one off, an error keeps the last answer, and the
/// answer survives a cold start.
struct FeatureFlagsTests {
    @Test("A name the server lists is on; every other name is off")
    func listedNameIsOn() async throws {
        let flags = try fresh()
        flags.listRequest = { completion in completion(.success(["edtf-date", "replay-web"])) }

        let refreshed = await refresh(flags)

        #expect(refreshed)
        #expect(flags.isEnabled("edtf-date"))
        #expect(flags.showsOnlyEDTFDate)
        #expect(!flags.isEnabled("glam-onboarding"))
    }

    @Test("An answer without edtf-date leaves the old date in place")
    func unlistedNameIsOff() async throws {
        let flags = try fresh()
        flags.listRequest = { completion in completion(.success(["replay-web"])) }

        _ = await refresh(flags)

        #expect(!flags.showsOnlyEDTFDate)
    }

    @Test("A server error keeps the last answer")
    func errorKeepsLastAnswer() async throws {
        let flags = try fresh()
        flags.apply(names: ["edtf-date"])
        flags.listRequest = { completion in completion(.failure(APIError.serverError)) }

        let refreshed = await refresh(flags)

        #expect(!refreshed)
        #expect(flags.showsOnlyEDTFDate)
    }

    @Test("The last answer survives a cold start; the very first start reads as off")
    func answerSurvivesColdStart() throws {
        let suite = "FeatureFlagsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(!FeatureFlags(defaults: defaults).showsOnlyEDTFDate)

        FeatureFlags(defaults: defaults).apply(names: ["edtf-date"])

        #expect(FeatureFlags(defaults: defaults).showsOnlyEDTFDate)
    }

    @Test("The completion runs on the main thread")
    func completionOnMain() async throws {
        let flags = try fresh()
        flags.listRequest = { completion in
            DispatchQueue.global().async { completion(.success([])) }
        }

        let onMain: Bool = await withCheckedContinuation { continuation in
            flags.refresh { _ in continuation.resume(returning: Thread.isMainThread) }
        }

        #expect(onMain)
    }

    @Test("The list call is a GET of /api/v2/feature-flags that needs no sign-in")
    func listCallShape() {
        let endpoint = FeatureFlagsV2Endpoint.list

        #expect(endpoint.method == .get)
        #expect(endpoint.customURL?.hasSuffix("/api/v2/feature-flags") == true)
        #expect(endpoint.skipAuthentication)
        #expect(endpoint.bodyData == nil)
    }

    // MARK: - Helpers

    /// A store on its own defaults, so no test reads another's answer.
    private func fresh() throws -> FeatureFlags {
        let defaults = try #require(UserDefaults(suiteName: "FeatureFlagsTests-\(UUID().uuidString)"))
        return FeatureFlags(defaults: defaults)
    }

    private func refresh(_ flags: FeatureFlags) async -> Bool {
        await withCheckedContinuation { continuation in
            flags.refresh { refreshed in continuation.resume(returning: refreshed) }
        }
    }
}
