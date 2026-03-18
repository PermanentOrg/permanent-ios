//
//  PublicProfilePageViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class PublicProfilePageViewModelTests: XCTestCase {

    func testGetProfileViewData_WhenNotEditable_ReturnsOnlyFilledCells() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: AccessRole.viewer.apiValue, type: ArchiveType.person.rawValue))

        let basic = BasicProfileItem()
        basic.fullName = "John Doe"
        basic.nickname = "JD"

        let blurb = BlurbProfileItem()
        blurb.shortDescription = "A short bio"

        let description = DescriptionProfileItem()
        description.longDescription = "A long description"

        sut.profileItems = [basic, blurb, description]

        let viewData = sut.getProfileViewData()

        XCTAssertFalse(containsCell(.archiveName, in: viewData[.about]))
        XCTAssertTrue(containsCell(.blurb, in: viewData[.about]))
        XCTAssertTrue(containsCell(.longDescription, in: viewData[.about]))
        XCTAssertTrue(containsCell(.fullName, in: viewData[.information]))
        XCTAssertTrue(containsCell(.nickName, in: viewData[.information]))
        XCTAssertNil(viewData[.profileVisibility])
    }

    func testGetProfileViewData_WhenEditable_IncludesEditableSections() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: AccessRole.owner.apiValue, type: ArchiveType.person.rawValue))

        let viewData = sut.getProfileViewData()

        XCTAssertTrue(containsCell(.profileVisibility, in: viewData[.profileVisibility]))
        XCTAssertEqual(viewData[.about]?.count, 3)
        XCTAssertTrue(containsCell(.archiveName, in: viewData[.about]))
        XCTAssertTrue(containsCell(.blurb, in: viewData[.about]))
        XCTAssertTrue(containsCell(.longDescription, in: viewData[.about]))
        XCTAssertEqual(viewData[.information]?.count, 5)
        XCTAssertTrue(containsCell(.fullName, in: viewData[.information]))
        XCTAssertTrue(containsCell(.nickName, in: viewData[.information]))
        XCTAssertTrue(containsCell(.gender, in: viewData[.information]))
        XCTAssertTrue(containsCell(.birthDate, in: viewData[.information]))
        XCTAssertTrue(containsCell(.birthLocation, in: viewData[.information]))
    }

    func testMilestonesProfileItems_SortsByDescendingStartDate() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: AccessRole.viewer.apiValue, type: ArchiveType.person.rawValue))

        let oldest = MilestoneProfileItem()
        oldest.title = "Old"
        oldest.startDateString = "2020-01-01"

        let newest = MilestoneProfileItem()
        newest.title = "New"
        newest.startDateString = "2025-01-01"

        let middle = MilestoneProfileItem()
        middle.title = "Mid"
        middle.startDateString = "2022-01-01"

        sut.profileItems = [oldest, newest, middle]

        let titles = sut.milestonesProfileItems.compactMap(\.title)
        XCTAssertEqual(titles, ["New", "Mid", "Old"])
    }

    private func containsCell(_ target: ProfileCellType, in cells: [ProfileCellType]?) -> Bool {
        guard let cells else { return false }

        return cells.contains { cell in
            switch (target, cell) {
            case (.profileVisibility, .profileVisibility),
                 (.blurb, .blurb),
                 (.longDescription, .longDescription),
                 (.fullName, .fullName),
                 (.nickName, .nickName),
                 (.gender, .gender),
                 (.birthDate, .birthDate),
                 (.birthLocation, .birthLocation),
                 (.onlinePresenceEmail, .onlinePresenceEmail),
                 (.onlinePresenceLink, .onlinePresenceLink),
                 (.establishedDate, .establishedDate),
                 (.establishedLocation, .establishedLocation),
                 (.milestone, .milestone),
                 (.archiveGallery, .archiveGallery),
                 (.archiveName, .archiveName):
                return true
            default:
                return false
            }
        }
    }

    private func makeArchiveData(accessRole: String, type: String) -> ArchiveVOData {
        ArchiveVOData(
            childFolderVOS: nil,
            folderSizeVOS: nil,
            recordVOS: nil,
            accessRole: accessRole,
            fullName: "Archive",
            spaceTotal: nil,
            spaceLeft: nil,
            fileTotal: nil,
            fileLeft: nil,
            relationType: nil,
            homeCity: nil,
            homeState: nil,
            homeCountry: nil,
            itemVOS: nil,
            birthDay: nil,
            company: nil,
            archiveVODescription: nil,
            archiveID: 1,
            publicDT: nil,
            archiveNbr: "0000-0001",
            view: nil,
            viewProperty: nil,
            archiveVOPublic: nil,
            vaultKey: nil,
            thumbArchiveNbr: nil,
            type: type,
            thumbStatus: nil,
            imageRatio: nil,
            thumbURL200: nil,
            thumbURL500: nil,
            thumbURL1000: nil,
            thumbURL2000: nil,
            thumbDT: nil,
            createdDT: nil,
            updatedDT: nil,
            status: .ok
        )
    }
}
