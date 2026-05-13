//
//  PublicProfilePicturesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class PublicProfilePicturesViewModelTests: XCTestCase {

    private func makeVM() -> PublicProfilePicturesViewModel {
        let vm = PublicProfilePicturesViewModel()
        vm.archiveData = ArchiveVOData.mock()
        return vm
    }

    func testInit_DefaultState() {
        let vm = makeVM()
        XCTAssertNil(vm.bannerURL)
        XCTAssertNil(vm.profilePicURL)
        XCTAssertNil(vm.publicRootFolder)
    }

    func testCanEditPublicProfilePhoto_WithMockArchive_ReturnsTrue() {
        let vm = makeVM()
        XCTAssertTrue(vm.canEditPublicProfilePhoto())
    }

    func testArchiveData_MockHasExpectedValues() {
        let vm = makeVM()
        XCTAssertEqual(vm.archiveData.archiveID, 1)
        XCTAssertEqual(vm.archiveData.archiveNbr, "1001")
    }

    func testProfilePicURL_SetAndRetrieve() throws {
        let vm = makeVM()
        let url = try XCTUnwrap(URL(string: "https://example.com/pic.jpg"))
        vm.profilePicURL = url
        XCTAssertEqual(vm.profilePicURL, url)
    }
}
