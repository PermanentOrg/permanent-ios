//
//  PublicGalleryTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 02.06.2022.
//

import XCTest

@testable import Permanent

class FailedVerificationPublicGalleryTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        return [
            URL(string: "\(APIEnvironment.defaultEnv.baseURL)/auth/verify"): "{\"Results\":[{\"data\":null,\"message\":[\"0 results found\"],\"status\":true,\"resultDT\":\"2022-06-02T07:28:12\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"a54ddb7d26fafe98ce2ead590ced1f0f\",\"createdDT\":null,\"updatedDT\":null}"
                .data(using: .utf8)!
        ]
    }
}

class PublicGalleryCodeTests: XCTestCase {
    var sut: PublicGalleryViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PublicGalleryViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - publicProfileURL

    func testPublicProfileURLgeneratorNegative() {
        let archiveNbr = ""

        XCTAssertNil(sut.publicProfileURL(archiveNbr: archiveNbr), "Empty archive number should produce nil URL")
    }

    func testPublicProfileURL_NilArchiveNbr_ReturnsNil() {
        XCTAssertNil(sut.publicProfileURL(archiveNbr: nil))
    }

    func testPublicProfileURL_ValidArchiveNbr_ReturnsURL() {
        let url = sut.publicProfileURL(archiveNbr: "0001-0000")
        XCTAssertNotNil(url)
    }

    func testPublicProfileURL_ContainsArchiveNbr() {
        let archiveNbr = "0001-0000"
        let url = sut.publicProfileURL(archiveNbr: archiveNbr)
        XCTAssertTrue(url?.absoluteString.contains(archiveNbr) == true)
    }

    func testPublicProfileURL_EndsWithProfile() {
        let url = sut.publicProfileURL(archiveNbr: "0001-0000")
        XCTAssertTrue(url?.absoluteString.hasSuffix("/profile") == true)
    }

    func testPublicProfileURL_ContainsArchivePath() {
        let url = sut.publicProfileURL(archiveNbr: "0001-0000")
        XCTAssertTrue(url?.absoluteString.contains("/archive/") == true)
    }

    // MARK: - Initial State

    func testInitialState_SearchPublicArchivesEmpty() {
        XCTAssertTrue(sut.searchPublicArchives.isEmpty)
    }

    func testInitialState_SearchQueryIsEmpty() {
        XCTAssertTrue(sut.searchQuery.isEmpty)
    }

    // MARK: - Search Archives

    func testSearchArchivesNegative() {
        let config = URLSessionConfiguration.ephemeral
        let numberOfArchivesInSearchResult = 0
        config.protocolClasses = [ResponseURLProtocol<FailedVerificationPublicGalleryTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)
        sut.searchQuery = "R"

        let promise = expectation(description: "Verify return of R search archives")

        sut.reallySearchArchives { result in
            XCTAssertEqual(result, .error(message: "Something went wrong. Please try again later."), "Failed! Negative test for public gallery.")
            XCTAssertEqual(self.sut.searchPublicArchives.count, numberOfArchivesInSearchResult, "Failed! Invalid number of archives returned.")
            promise.fulfill()
        }

        wait(for: [promise], timeout: 6)
    }
}
