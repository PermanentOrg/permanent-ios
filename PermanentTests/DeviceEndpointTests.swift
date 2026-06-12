//
//  DeviceEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.

import XCTest
@testable import Permanent

final class DeviceEndpointTests: XCTestCase {

    // MARK: - Path Tests

    func testNewEndpoint_HasCorrectPath() {
        let endpoint = DeviceEndpoint.new(params: "test-token-123")

        XCTAssertEqual(endpoint.path, "/device/registerDevice", "New device endpoint should use /device/registerDevice path")
    }

    func testDeleteEndpoint_HasCorrectPath() {
        let endpoint = DeviceEndpoint.delete(params: "test-token-456")

        XCTAssertEqual(endpoint.path, "/device/deleteToken", "Delete device endpoint should use /device/deleteToken path")
    }

    // MARK: - HTTP Method Tests

    func testNewEndpoint_UsesPOSTMethod() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertEqual(endpoint.method, .post, "New device endpoint should use POST method")
    }

    func testDeleteEndpoint_UsesPOSTMethod() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertEqual(endpoint.method, .post, "Delete device endpoint should use POST method")
    }

    // MARK: - Request & Response Type Tests

    func testNewEndpoint_HasDataRequestType() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertEqual(endpoint.requestType, .data, "New device endpoint should have data request type")
    }

    func testDeleteEndpoint_HasDataRequestType() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertEqual(endpoint.requestType, .data, "Delete device endpoint should have data request type")
    }

    func testNewEndpoint_HasJSONResponseType() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertEqual(endpoint.responseType, .json, "New device endpoint should have JSON response type")
    }

    func testDeleteEndpoint_HasJSONResponseType() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertEqual(endpoint.responseType, .json, "Delete device endpoint should have JSON response type")
    }

    // MARK: - Parameters Tests

    func testNewEndpoint_HasNonNilParameters() {
        let endpoint = DeviceEndpoint.new(params: "fcm-push-token-abc")

        XCTAssertNotNil(endpoint.parameters, "New device endpoint should produce non-nil parameters from Payloads.devicePayload")
    }

    func testDeleteEndpoint_HasNonNilParameters() {
        let endpoint = DeviceEndpoint.delete(params: "fcm-push-token-xyz")

        XCTAssertNotNil(endpoint.parameters, "Delete device endpoint should produce non-nil parameters from Payloads.devicePayload")
    }

    // MARK: - Nil Property Tests

    func testNewEndpoint_HasNilBodyData() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertNil(endpoint.bodyData, "New device endpoint should have nil bodyData")
    }

    func testDeleteEndpoint_HasNilBodyData() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertNil(endpoint.bodyData, "Delete device endpoint should have nil bodyData")
    }

    func testNewEndpoint_HasNilCustomURL() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertNil(endpoint.customURL, "New device endpoint should have nil customURL")
    }

    func testDeleteEndpoint_HasNilCustomURL() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertNil(endpoint.customURL, "Delete device endpoint should have nil customURL")
    }

    func testNewEndpoint_HasNilProgressHandler() {
        let endpoint = DeviceEndpoint.new(params: "token")

        XCTAssertNil(endpoint.progressHandler, "New device endpoint should have nil progressHandler")
    }

    func testDeleteEndpoint_HasNilProgressHandler() {
        let endpoint = DeviceEndpoint.delete(params: "token")

        XCTAssertNil(endpoint.progressHandler, "Delete device endpoint should have nil progressHandler")
    }
}
