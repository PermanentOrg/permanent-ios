//
//  UploadQuotaGateTests.swift
//  PermanentTests
//

import Foundation
import Testing
@testable import Permanent

/// The upload gate's second opinion: the archive payer's storage can only turn a refusal into a
/// pass. Every row of the outcome table is pinned here, plus the byte parsing and the endpoint shape.
struct UploadQuotaGateTests {

    // MARK: - The payer's answer, one row per outcome

    @Test("A payer with room allows")
    func payerWithRoomAllows() throws {
        let result = try ok("2147483648")
        #expect(UploadManager.payerHasRoom(result, filesSize: 250_000_000))
    }

    @Test("A payer short of the upload blocks, and an exact fit is still short",
          arguments: [("100", 250_000_000), ("5000", 5000), ("-5", 1)])
    func payerShortBlocks(spaceLeft: String, filesSize: Int) throws {
        let result = try ok(spaceLeft)
        #expect(!UploadManager.payerHasRoom(result, filesSize: filesSize))
    }

    /// A 200 proves a payer exists, so a figure we cannot read is the same as a missing one: allow,
    /// and let the server decide.
    @Test("A 200 without a readable figure allows", arguments: [nil, "plenty"] as [String?])
    func unreadableFigureAllows(spaceLeft: String?) throws {
        let result = try ok(spaceLeft)
        #expect(UploadManager.payerHasRoom(result, filesSize: 250_000_000))
    }

    @Test("A 200 object without the spaceLeft key allows")
    func objectWithoutKeyAllows() throws {
        let http = try response(200)
        #expect(UploadManager.payerHasRoom(.json(["items": [1, 2, 3]], http), filesSize: 1))
    }

    @Test("A failed call leaves the account's own refusal standing",
          arguments: [(APIError.clientError, 404), (.badRequest, 400), (.unauthorized, 401), (.serverError, 500)])
    func failedCallBlocks(error: APIError, code: Int) throws {
        let http = try response(code)
        #expect(!UploadManager.payerHasRoom(.error(error, http), filesSize: 1))
    }

    @Test("Offline blocks")
    func offlineBlocks() {
        #expect(!UploadManager.payerHasRoom(.error(URLError(.notConnectedToInternet), nil), filesSize: 1))
    }

    @Test("A 200 body that is not an object blocks before it reaches the decoder")
    func nonObjectBodyBlocks() throws {
        let http = try response(200)
        #expect(!UploadManager.payerHasRoom(.json([1, 2, 3], http), filesSize: 1))
        #expect(!UploadManager.payerHasRoom(.json("<html>proxy</html>", http), filesSize: 1))
        #expect(!UploadManager.payerHasRoom(.json(nil, http), filesSize: 1))
    }

    @Test("A file result blocks")
    func fileResultBlocks() throws {
        let http = try response(200)
        #expect(!UploadManager.payerHasRoom(.file(nil, http), filesSize: 1))
    }

    // MARK: - spaceLeftBytes

    @Test("spaceLeft parses as bytes, past Int32 and below zero",
          arguments: [("2147483648", 2_147_483_648), ("0", 0), ("-5", -5)])
    func spaceLeftParses(text: String, bytes: Int) {
        #expect(PayerAccountStorageV2Data(spaceLeft: text).spaceLeftBytes == bytes)
    }

    @Test("Unreadable spaceLeft forms parse as nil",
          arguments: [nil, "", "abc", "1.5", "99999999999999999999"] as [String?])
    func unreadableSpaceLeftIsNil(text: String?) {
        #expect(PayerAccountStorageV2Data(spaceLeft: text).spaceLeftBytes == nil)
    }

    // MARK: - hasRoom

    @Test("An unknown remaining figure never blocks")
    func unknownRemainingNeverBlocks() {
        #expect(UploadManager.hasRoom(remainingBytes: nil, filesSize: 999_999_999))
    }

    @Test("Room means strictly more than the upload", arguments: [
        (remaining: 5000, filesSize: 4999, fits: true),
        (remaining: 5000, filesSize: 5000, fits: false),
        (remaining: 5000, filesSize: 5001, fits: false),
        (remaining: 0, filesSize: 1, fits: false)
    ])
    func boundary(_ row: (remaining: Int, filesSize: Int, fits: Bool)) {
        #expect(UploadManager.hasRoom(remainingBytes: row.remaining, filesSize: row.filesSize) == row.fits)
    }

    // MARK: - The reported scenario

    @Test("A member out of room uploads into an archive whose payer has room")
    func memberFullPayerNotAllows() throws {
        let memberSpaceLeft = 100 * 1024 * 1024
        let upload = 300 * 1024 * 1024
        #expect(!UploadManager.hasRoom(remainingBytes: memberSpaceLeft, filesSize: upload),
                "The account check must still come up short; that is what triggers the payer call")
        let payer = try ok("53687091200")
        #expect(UploadManager.payerHasRoom(payer, filesSize: upload))
    }

    @Test("A payer that is also full still blocks")
    func payerAlsoFullBlocks() throws {
        let payer = try ok("1048576")
        #expect(!UploadManager.payerHasRoom(payer, filesSize: 300 * 1024 * 1024))
    }

    // MARK: - Endpoint shape

    private var payerEndpoint: ArchiveV2Endpoint { .payerAccountStorage(archiveId: 42) }
    private var payerURL: String { "\(APIEnvironment.defaultEnv.apiServer)api/v2/archives/42/payer-account-storage" }

    @Test("The path is the documented plural route, not the deprecated singular alias")
    func documentedPluralPath() {
        #expect(payerEndpoint.customURL == payerURL)
    }

    @Test("The request ignores the legacy base URL it is handed")
    func requestIgnoresLegacyBaseURL() throws {
        let request = try #require(payerEndpoint.urlRequest(with: APIEnvironment.staging))
        #expect(request.url?.absoluteString == payerURL)
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }

    @Test("It is an authenticated V2 read")
    func authenticatedV2Read() {
        #expect(payerEndpoint.method == .get)
        #expect(payerEndpoint.requestType == .data)
        #expect(payerEndpoint.responseType == .json)
        #expect(isNil(payerEndpoint.parameters))
        #expect(payerEndpoint.bodyData == nil)
        #expect(payerEndpoint.shareToken == nil)
        #expect(!payerEndpoint.skipAuthentication)
        #expect(payerEndpoint.headers?["Request-Version"] == "2")
        #expect(payerEndpoint.headers?["Content-Type"] == "application/json")
    }

    /// A pre-check with a fallback must never force a logout.
    @Test("A 401 here never forces a logout")
    func doesNotForceLogoutOn401() {
        #expect(payerEndpoint.ignoreErrors)
    }

    @Test("The archive search is undisturbed")
    func searchArchivesUndisturbed() {
        let search = ArchiveV2Endpoint.searchArchives(callerMembershipRoles: ["owner"], pageSize: 100)
        #expect(search.customURL == "\(APIEnvironment.defaultEnv.apiServer)api/v2/archives?callerMembershipRole=owner&pageSize=100")
    }

    // MARK: - Model decoding

    @Test("The bare object with quoted fields decodes")
    func decodesBareObject() throws {
        let json = """
        {"accountSpaceId":"9","accountId":"2","spaceLeft":"2147483648","spaceTotal":"2147483648",
         "filesLeft":"100000","filesTotal":"100000","status":"status.generic.ok",
         "type":"type.generic.placeholder","createdDt":"2026-09-01T00:00:00.000Z",
         "updatedDt":"2026-09-01T00:00:00.000Z"}
        """
        let model = try PayerAccountStorageV2Data.decoder.decode(PayerAccountStorageV2Data.self, from: Data(json.utf8))
        #expect(model.spaceLeftBytes == 2_147_483_648)
    }

    @Test("The dictionary the dispatcher hands over decodes")
    func decodesDispatcherDictionary() throws {
        let decoded: PayerAccountStorageV2Data? = JSONHelper.decoding(from: payerBody("512"), with: PayerAccountStorageV2Data.decoder)
        let model = try #require(decoded)
        #expect(model.spaceLeftBytes == 512)
    }

    @Test("A missing spaceLeft still decodes, with no figure")
    func missingSpaceLeftDecodes() throws {
        let decoded: PayerAccountStorageV2Data? = JSONHelper.decoding(from: payerBody(nil), with: PayerAccountStorageV2Data.decoder)
        let model = try #require(decoded)
        #expect(model.spaceLeftBytes == nil)
    }

    // MARK: - Helpers

    /// The bare object Stela returns, every field quoted, with or without the one field that matters.
    private func payerBody(_ spaceLeft: String?) -> [String: Any] {
        var body: [String: Any] = [
            "accountSpaceId": "9",
            "accountId": "2",
            "spaceTotal": "2147483648",
            "filesLeft": "100000",
            "filesTotal": "100000",
            "status": "status.generic.ok",
            "type": "type.generic.placeholder",
            "createdDt": "2026-09-01T00:00:00.000Z",
            "updatedDt": "2026-09-01T00:00:00.000Z"
        ]
        if let spaceLeft { body["spaceLeft"] = spaceLeft }
        return body
    }

    /// `RequestParameters` is `Any`, so the optional cannot be compared against nil directly.
    private func isNil(_ value: Any?) -> Bool {
        if case .none = value { return true }
        return false
    }

    private func response(_ code: Int, sourceLocation: SourceLocation = #_sourceLocation) throws -> HTTPURLResponse {
        let url = try #require(URL(string: payerURL), sourceLocation: sourceLocation)
        return try #require(HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil), sourceLocation: sourceLocation)
    }

    private func ok(_ spaceLeft: String?, sourceLocation: SourceLocation = #_sourceLocation) throws -> OperationResult {
        .json(payerBody(spaceLeft), try response(200, sourceLocation: sourceLocation))
    }
}
