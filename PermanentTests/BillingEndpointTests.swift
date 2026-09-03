//
//  BillingEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 02.09.2026.
//

import XCTest
@testable import Permanent

final class BillingEndpointTests: XCTestCase {

    private func bodyJSON(_ endpoint: BillingEndpoint) -> [String: Any]? {
        guard let data = endpoint.bodyData else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: - purchaseStorage request shape

    func testPurchaseStorage_UsesPostMethod() {
        XCTAssertEqual(BillingEndpoint.purchaseStorage(amountInUSD: 10).method, .post)
    }

    func testPurchaseStorage_TargetsStelaStoragePurchases() {
        let url = BillingEndpoint.purchaseStorage(amountInUSD: 10).customURL
        XCTAssertEqual(url, "\(APIEnvironment.defaultEnv.apiServer)api/v2/storage-purchases")
    }

    func testPurchaseStorage_BodyCarriesOnlyAmountInUSD() {
        let body = bodyJSON(.purchaseStorage(amountInUSD: 25))
        XCTAssertEqual(body?["amountInUSD"] as? Int, 25)
        XCTAssertEqual(body?.count, 1)
    }

    func testPurchaseStorage_SendsJSONContentType() {
        let headers = BillingEndpoint.purchaseStorage(amountInUSD: 10).headers
        XCTAssertEqual(headers?["content-type"], "application/json")
    }

    func testPurchaseStorage_IsAuthenticatedDataRequest() {
        let endpoint = BillingEndpoint.purchaseStorage(amountInUSD: 10)
        XCTAssertEqual(endpoint.requestType, .data)
        XCTAssertEqual(endpoint.responseType, .json)
        XCTAssertFalse(endpoint.skipAuthentication)
        XCTAssertFalse(endpoint.ignoreErrors)
        XCTAssertNil(endpoint.shareToken)
        XCTAssertNil(endpoint.parameters)
    }

    func testPurchaseStorage_URLRequestIgnoresLegacyBaseURL() {
        let request = BillingEndpoint.purchaseStorage(amountInUSD: 10).urlRequest(with: APIEnvironment.staging)
        XCTAssertEqual(request?.url?.absoluteString, "\(APIEnvironment.defaultEnv.apiServer)api/v2/storage-purchases")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertNotNil(request?.httpBody)
    }

    // MARK: - giftStorage stays on its V2 route

    func testGiftStorage_TargetsStelaBillingGift() {
        let gift = GiftingModel(storageAmount: 1, recipientEmails: ["a@b.com"], note: "")
        let url = BillingEndpoint.giftStorage(gift: gift).customURL
        XCTAssertEqual(url, "\(APIEnvironment.defaultEnv.apiServer)api/v2/billing/gift")
    }

    // MARK: - StoragePurchaseResponse decoding

    func testStoragePurchaseResponse_DecodesClientSecret() {
        let json: [String: Any] = ["data": ["clientSecret": "pi_123_secret_456"]]
        let response: StoragePurchaseResponse? = JSONHelper.decoding(from: json, with: StoragePurchaseResponse.decoder)
        XCTAssertEqual(response?.data?.clientSecret, "pi_123_secret_456")
    }

    func testStoragePurchaseResponse_MissingSecret_DecodesToNil() {
        let json: [String: Any] = ["data": [String: Any]()]
        let response: StoragePurchaseResponse? = JSONHelper.decoding(from: json, with: StoragePurchaseResponse.decoder)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.data?.clientSecret)
    }

    func testStoragePurchaseResponse_ErrorBody_HasNoData() {
        let json: [String: Any] = ["errors": [["name": "Unauthorized", "message": "401", "source": "auth"]]]
        let response: StoragePurchaseResponse? = JSONHelper.decoding(from: json, with: StoragePurchaseResponse.decoder)
        XCTAssertNotNil(response)
        XCTAssertNil(response?.data)
    }
}
