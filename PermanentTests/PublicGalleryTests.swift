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

    func testPublicProfileURLgeneratorNegative() {
        let archiveNbr = ""
        let generatedURL: URL? = nil

        let promise = expectation(description: "Test for URL generation")

        XCTAssertEqual(sut.publicProfileURL(archiveNbr: archiveNbr), generatedURL, "Failed! Checked valid MFA verification code.")
        promise.fulfill()

        wait(for: [promise], timeout: 6)
    }

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
