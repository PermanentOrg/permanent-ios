//
//  LegacyPlanningEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class LegacyPlanningEndpointTests: XCTestCase {

    private let apiServer = APIEnvironment.defaultEnv.apiServer

    // MARK: - Helper

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Path Tests

    func testGetLegacyContact_PathIsEmpty() {
        let endpoint = LegacyPlanningEndpoint.getLegacyContact
        XCTAssertEqual(endpoint.path, "")
    }

    func testGetArchiveSteward_PathIsEmpty() {
        let endpoint = LegacyPlanningEndpoint.getArchiveSteward(archiveId: 42)
        XCTAssertEqual(endpoint.path, "")
    }

    func testSetArchiveSteward_PathIsEmpty() {
        let details = LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        XCTAssertEqual(endpoint.path, "")
    }

    func testSetAccountSteward_PathIsEmpty() {
        let endpoint = LegacyPlanningEndpoint.setAccountSteward(name: "John", stewardEmail: "j@b.com")
        XCTAssertEqual(endpoint.path, "")
    }

    func testUpdateAccountSteward_PathIsEmpty() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: "Jane", stewardEmail: nil)
        XCTAssertEqual(endpoint.path, "")
    }

    func testUpdateArchiveSteward_PathIsEmpty() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: "note")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        XCTAssertEqual(endpoint.path, "")
    }

    // MARK: - HTTP Method Tests

    func testGetLegacyContact_MethodIsGet() {
        let endpoint = LegacyPlanningEndpoint.getLegacyContact
        XCTAssertEqual(endpoint.method, .get)
    }

    func testGetArchiveSteward_MethodIsGet() {
        let endpoint = LegacyPlanningEndpoint.getArchiveSteward(archiveId: 10)
        XCTAssertEqual(endpoint.method, .get)
    }

    func testSetArchiveSteward_MethodIsPost() {
        let details = LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        XCTAssertEqual(endpoint.method, .post)
    }

    func testSetAccountSteward_MethodIsPost() {
        let endpoint = LegacyPlanningEndpoint.setAccountSteward(name: "John", stewardEmail: "j@b.com")
        XCTAssertEqual(endpoint.method, .post)
    }

    func testUpdateAccountSteward_MethodIsPut() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil)
        XCTAssertEqual(endpoint.method, .put)
    }

    func testUpdateArchiveSteward_MethodIsPut() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: "")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        XCTAssertEqual(endpoint.method, .put)
    }

    // MARK: - Headers Tests

    func testAllEndpoints_HaveJsonContentTypeHeader() {
        let endpoints: [LegacyPlanningEndpoint] = [
            .getLegacyContact,
            .getArchiveSteward(archiveId: 1),
            .setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")),
            .setAccountSteward(name: "N", stewardEmail: "e@e.com"),
            .updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil),
            .updateArchiveSteward(directiveId: "d1", stewardDetails: LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: ""))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.headers?["content-type"], "application/json", "Header mismatch for \(endpoint)")
        }
    }

    // MARK: - Custom URL Tests

    func testGetLegacyContact_CustomURL() {
        let endpoint = LegacyPlanningEndpoint.getLegacyContact
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/legacy-contact")
    }

    func testGetArchiveSteward_CustomURLContainsArchiveId() {
        let endpoint = LegacyPlanningEndpoint.getArchiveSteward(archiveId: 99)
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/directive/archive/99")
    }

    func testSetArchiveSteward_CustomURL() {
        let details = LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/directive")
    }

    func testSetAccountSteward_CustomURL() {
        let endpoint = LegacyPlanningEndpoint.setAccountSteward(name: "John", stewardEmail: "j@b.com")
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/legacy-contact")
    }

    func testUpdateAccountSteward_CustomURLContainsLegacyContactId() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "abc123", name: nil, stewardEmail: nil)
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/legacy-contact/abc123")
    }

    func testUpdateArchiveSteward_CustomURLContainsDirectiveId() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: "")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "dir456", stewardDetails: details)
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/directive/dir456")
    }

    // MARK: - BodyData & ProgressHandler Tests

    func testAllEndpoints_BodyDataIsNil() {
        let endpoints: [LegacyPlanningEndpoint] = [
            .getLegacyContact,
            .getArchiveSteward(archiveId: 1),
            .setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")),
            .setAccountSteward(name: "N", stewardEmail: "e@e.com"),
            .updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil),
            .updateArchiveSteward(directiveId: "d1", stewardDetails: LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: ""))
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.bodyData, "bodyData should be nil for \(endpoint)")
        }
    }

    func testAllEndpoints_ProgressHandlerIsNil() {
        let endpoints: [LegacyPlanningEndpoint] = [
            .getLegacyContact,
            .getArchiveSteward(archiveId: 1),
            .setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")),
            .setAccountSteward(name: "N", stewardEmail: "e@e.com"),
            .updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil),
            .updateArchiveSteward(directiveId: "d1", stewardDetails: LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: ""))
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.progressHandler, "progressHandler should be nil for \(endpoint)")
        }
    }

    // MARK: - Parameters Tests (getLegacyContact / getArchiveSteward return arrays)

    func testGetLegacyContact_ParametersIsEmptyArray() {
        let endpoint = LegacyPlanningEndpoint.getLegacyContact
        let params = endpoint.parameters
        XCTAssertNotNil(params)
        let array = params as? [Any]
        XCTAssertNotNil(array, "getLegacyContact parameters should be an array")
        XCTAssertEqual(array?.count, 0, "getLegacyContact parameters should be empty")
    }

    func testGetArchiveSteward_ParametersIsEmptyArray() {
        let endpoint = LegacyPlanningEndpoint.getArchiveSteward(archiveId: 5)
        let params = endpoint.parameters
        XCTAssertNotNil(params)
        let array = params as? [Any]
        XCTAssertNotNil(array, "getArchiveSteward parameters should be an array")
        XCTAssertEqual(array?.count, 0, "getArchiveSteward parameters should be empty")
    }

    // MARK: - setArchiveSteward Parameters

    func testSetArchiveSteward_ParametersContainRequiredFields() {
        let details = LegacyPlanningArchiveDetails(archiveId: 42, stewardEmail: "steward@example.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertEqual(params?["stewardEmail"] as? String, "steward@example.com")
        XCTAssertEqual(params?["type"] as? String, "transfer")
        XCTAssertEqual(params?["archiveId"] as? String, "42")

        let trigger = params?["trigger"] as? [String: Any]
        XCTAssertNotNil(trigger)
        XCTAssertEqual(trigger?["type"] as? String, "admin")
    }

    func testSetArchiveSteward_WithNonEmptyNote_IncludesNote() {
        let details = LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "s@e.com", note: "Please take care")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["note"] as? String, "Please take care")
    }

    func testSetArchiveSteward_WithEmptyNote_ExcludesNote() {
        let details = LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "s@e.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertNil(params?["note"], "Empty note should not be included in parameters")
    }

    func testSetArchiveSteward_WithNilArchiveId_UsesZero() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "s@e.com", note: "")
        let endpoint = LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["archiveId"] as? String, "0")
    }

    // MARK: - updateArchiveSteward Parameters

    func testUpdateArchiveSteward_ParametersDoNotContainArchiveId() {
        let details = LegacyPlanningArchiveDetails(archiveId: 99, stewardEmail: "s@e.com", note: "")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertNil(params?["archiveId"], "updateArchiveSteward should not include archiveId")
    }

    func testUpdateArchiveSteward_ParametersContainStewardEmailAndType() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "updated@e.com", note: "")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["stewardEmail"] as? String, "updated@e.com")
        XCTAssertEqual(params?["type"] as? String, "transfer")

        let trigger = params?["trigger"] as? [String: Any]
        XCTAssertEqual(trigger?["type"] as? String, "admin")
    }

    func testUpdateArchiveSteward_WithNonEmptyNote_IncludesNote() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "s@e.com", note: "Important note")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["note"] as? String, "Important note")
    }

    func testUpdateArchiveSteward_WithEmptyNote_ExcludesNote() {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "s@e.com", note: "")
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: "d1", stewardDetails: details)
        let params = dict(endpoint.parameters)

        XCTAssertNil(params?["note"], "Empty note should not be included in parameters")
    }

    // MARK: - setAccountSteward Parameters

    func testSetAccountSteward_ParametersContainNameAndEmail() {
        let endpoint = LegacyPlanningEndpoint.setAccountSteward(name: "Alice", stewardEmail: "alice@example.com")
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertEqual(params?["name"] as? String, "Alice")
        XCTAssertEqual(params?["email"] as? String, "alice@example.com")
    }

    // MARK: - updateAccountSteward Parameters

    func testUpdateAccountSteward_WithBothNameAndEmail_IncludesBoth() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: "Bob", stewardEmail: "bob@e.com")
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertEqual(params?["name"] as? String, "Bob")
        XCTAssertEqual(params?["email"] as? String, "bob@e.com")
    }

    func testUpdateAccountSteward_WithNilName_ExcludesName() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: "bob@e.com")
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertNil(params?["name"], "Nil name should not be included")
        XCTAssertEqual(params?["email"] as? String, "bob@e.com")
    }

    func testUpdateAccountSteward_WithNilEmail_ExcludesEmail() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: "Bob", stewardEmail: nil)
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertEqual(params?["name"] as? String, "Bob")
        XCTAssertNil(params?["email"], "Nil email should not be included")
    }

    func testUpdateAccountSteward_WithBothNil_ReturnsEmptyDict() {
        let endpoint = LegacyPlanningEndpoint.updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil)
        let params = dict(endpoint.parameters)

        XCTAssertNotNil(params)
        XCTAssertTrue(params?.isEmpty ?? false, "Both nil should produce empty dictionary")
    }

    // MARK: - RequestType / ResponseType Tests

    func testAllEndpoints_RequestTypeIsData() {
        let endpoints: [LegacyPlanningEndpoint] = [
            .getLegacyContact,
            .getArchiveSteward(archiveId: 1),
            .setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")),
            .setAccountSteward(name: "N", stewardEmail: "e@e.com"),
            .updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil),
            .updateArchiveSteward(directiveId: "d1", stewardDetails: LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: ""))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.requestType, .data, "requestType should be .data for \(endpoint)")
        }
    }

    func testAllEndpoints_ResponseTypeIsJson() {
        let endpoints: [LegacyPlanningEndpoint] = [
            .getLegacyContact,
            .getArchiveSteward(archiveId: 1),
            .setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: 1, stewardEmail: "a@b.com", note: "")),
            .setAccountSteward(name: "N", stewardEmail: "e@e.com"),
            .updateAccountSteward(legacyContactId: "lc1", name: nil, stewardEmail: nil),
            .updateArchiveSteward(directiveId: "d1", stewardDetails: LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: "x@y.com", note: ""))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.responseType, .json, "responseType should be .json for \(endpoint)")
        }
    }
}
