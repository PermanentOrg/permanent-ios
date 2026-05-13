//
//  EventsEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class EventsEndpointTests: XCTestCase {

    private let apiServer = APIEnvironment.defaultEnv.apiServer

    // MARK: - Helpers

    private func makePayload() -> EventsPayload {
        return EventsPayload(
            entity: "account",
            action: "submit",
            version: 1,
            entityId: "123",
            body: EventsBodyPayload(event: "test_event", distinctId: "user_1", data: [:])
        )
    }

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Path Tests

    func testSendEvent_PathIsEmpty() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertEqual(endpoint.path, "")
    }

    func testChecklist_PathIsEmpty() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertEqual(endpoint.path, "")
    }

    // MARK: - Method Tests

    func testSendEvent_MethodIsPost() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertEqual(endpoint.method, .post)
    }

    func testChecklist_MethodIsGet() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertEqual(endpoint.method, .get)
    }

    // MARK: - Custom URL Tests

    func testSendEvent_CustomURL() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/event")
    }

    func testChecklist_CustomURL() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertEqual(endpoint.customURL, "\(apiServer)api/v2/event/checklist")
    }

    // MARK: - RequestType / ResponseType Tests

    func testSendEvent_RequestTypeIsData() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testChecklist_RequestTypeIsData() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testSendEvent_ResponseTypeIsJson() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertEqual(endpoint.responseType, .json)
    }

    func testChecklist_ResponseTypeIsJson() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertEqual(endpoint.responseType, .json)
    }

    // MARK: - ProgressHandler Tests

    func testSendEvent_ProgressHandlerIsNil() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertNil(endpoint.progressHandler)
    }

    func testChecklist_ProgressHandlerIsNil() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - BodyData Tests

    func testSendEvent_BodyDataIsNotNil() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        XCTAssertNotNil(endpoint.bodyData, "sendEvent should encode the payload into bodyData")
    }

    func testSendEvent_BodyDataIsValidJSON() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        guard let data = endpoint.bodyData else {
            XCTFail("bodyData should not be nil")
            return
        }
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertNotNil(json, "bodyData should be valid JSON")
    }

    func testChecklist_BodyDataIsNil() {
        let endpoint = EventsEndpoint.checklist
        XCTAssertNil(endpoint.bodyData, "checklist should not have bodyData")
    }

    // MARK: - Parameters Tests (sendEvent)

    func testSendEvent_ParametersContainEntity() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["entity"] as? String, "account")
    }

    func testSendEvent_ParametersContainAction() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["action"] as? String, "submit")
    }

    func testSendEvent_ParametersContainVersion() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["version"] as? Int, 1)
    }

    func testSendEvent_ParametersContainEntityId() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["entityId"] as? String, "123")
    }

    func testSendEvent_ParametersContainNestedBodyAnalytics() {
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: makePayload())
        let params = dict(endpoint.parameters)

        let body = params?["body"] as? [String: Any]
        XCTAssertNotNil(body, "Parameters should contain a 'body' dictionary")

        let analytics = body?["analytics"] as? [String: Any]
        XCTAssertNotNil(analytics, "body should contain 'analytics' dictionary")
        XCTAssertEqual(analytics?["event"] as? String, "test_event")
        XCTAssertEqual(analytics?["distinctId"] as? String, "user_1")
    }

    // MARK: - Parameters Tests (checklist)

    func testChecklist_ParametersIsEmptyArray() {
        let endpoint = EventsEndpoint.checklist
        let params = endpoint.parameters
        XCTAssertNotNil(params)
        let array = params as? [Any]
        XCTAssertNotNil(array, "checklist parameters should be an array")
        XCTAssertEqual(array?.count, 0, "checklist parameters should be empty")
    }

    // MARK: - Encoded BodyData Content Validation

    func testSendEvent_EncodedBodyContainsExpectedFields() {
        let payload = makePayload()
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: payload)
        guard let data = endpoint.bodyData,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            XCTFail("bodyData should be decodable JSON dictionary")
            return
        }

        XCTAssertEqual(json["entity"] as? String, "account")
        XCTAssertEqual(json["action"] as? String, "submit")
        XCTAssertEqual(json["version"] as? Int, 1)
        XCTAssertEqual(json["entityId"] as? String, "123")
    }

    func testSendEvent_EncodedBodyContainsAnalyticsInsideBody() {
        let payload = makePayload()
        let endpoint = EventsEndpoint.sendEvent(eventsPayload: payload)
        guard let data = endpoint.bodyData,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            XCTFail("bodyData should be decodable JSON dictionary")
            return
        }

        let body = json["body"] as? [String: Any]
        let analytics = body?["analytics"] as? [String: Any]
        XCTAssertNotNil(analytics, "Encoded body should contain analytics nested under body")
        XCTAssertEqual(analytics?["event"] as? String, "test_event")
        XCTAssertEqual(analytics?["distinctId"] as? String, "user_1")
    }
}
