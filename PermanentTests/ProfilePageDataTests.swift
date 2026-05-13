//
//  ProfilePageDataTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ProfilePageDataTests: XCTestCase {

    // MARK: - nameTitle

    func testNameTitle_Person_ReturnsFullName() {
        let result = ProfilePageData.nameTitle(archiveType: .person)
        XCTAssertFalse(result.isEmpty)
    }

    func testNameTitle_Individual_ReturnsFullName() {
        let result = ProfilePageData.nameTitle(archiveType: .individual)
        XCTAssertEqual(result, ProfilePageData.nameTitle(archiveType: .person))
    }

    func testNameTitle_Family_ReturnsFamilyNickname() {
        let result = ProfilePageData.nameTitle(archiveType: .family)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, ProfilePageData.nameTitle(archiveType: .person))
    }

    func testNameTitle_FamilyHistory_MatchesFamily() {
        XCTAssertEqual(
            ProfilePageData.nameTitle(archiveType: .familyHistory),
            ProfilePageData.nameTitle(archiveType: .family)
        )
    }

    func testNameTitle_Organization_ReturnsLegalName() {
        let result = ProfilePageData.nameTitle(archiveType: .organization)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, ProfilePageData.nameTitle(archiveType: .person))
        XCTAssertNotEqual(result, ProfilePageData.nameTitle(archiveType: .family))
    }

    func testNameTitle_Community_MatchesOrganization() {
        XCTAssertEqual(
            ProfilePageData.nameTitle(archiveType: .community),
            ProfilePageData.nameTitle(archiveType: .organization)
        )
    }

    func testNameTitle_NonProfit_ReturnsLegalName() {
        let result = ProfilePageData.nameTitle(archiveType: .nonProfit)
        XCTAssertFalse(result.isEmpty)
    }

    func testNameTitle_Other_MatchesPerson() {
        XCTAssertEqual(
            ProfilePageData.nameTitle(archiveType: .other),
            ProfilePageData.nameTitle(archiveType: .person)
        )
    }

    func testNameTitle_Unsure_MatchesPerson() {
        XCTAssertEqual(
            ProfilePageData.nameTitle(archiveType: .unsure),
            ProfilePageData.nameTitle(archiveType: .person)
        )
    }

    // MARK: - nickNameTitle

    func testNickNameTitle_Person_ReturnsNickname() {
        let result = ProfilePageData.nickNameTitle(archiveType: .person)
        XCTAssertFalse(result.isEmpty)
    }

    func testNickNameTitle_Family_ReturnsPreviousName() {
        let result = ProfilePageData.nickNameTitle(archiveType: .family)
        XCTAssertNotEqual(result, ProfilePageData.nickNameTitle(archiveType: .person))
    }

    func testNickNameTitle_Organization_ReturnsDBAName() {
        let result = ProfilePageData.nickNameTitle(archiveType: .organization)
        XCTAssertNotEqual(result, ProfilePageData.nickNameTitle(archiveType: .person))
        XCTAssertNotEqual(result, ProfilePageData.nickNameTitle(archiveType: .family))
    }

    func testNickNameTitle_NonProfit_MatchesOrganization() {
        XCTAssertEqual(
            ProfilePageData.nickNameTitle(archiveType: .nonProfit),
            ProfilePageData.nickNameTitle(archiveType: .organization)
        )
    }

    // MARK: - genderTitle

    func testGenderTitle_Person_ReturnsNonEmpty() {
        let result = ProfilePageData.genderTitle(archiveType: .person)
        XCTAssertFalse(result.isEmpty)
    }

    func testGenderTitle_Family_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderTitle(archiveType: .family).isEmpty)
    }

    func testGenderTitle_Organization_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderTitle(archiveType: .organization).isEmpty)
    }

    func testGenderTitle_NonProfit_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderTitle(archiveType: .nonProfit).isEmpty)
    }

    func testGenderTitle_Community_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderTitle(archiveType: .community).isEmpty)
    }

    // MARK: - birthDateTitle

    func testBirthDateTitle_Person_ReturnsBirthDate() {
        let result = ProfilePageData.birthDateTitle(archiveType: .person)
        XCTAssertFalse(result.isEmpty)
    }

    func testBirthDateTitle_Family_ReturnsDateEstablished() {
        let result = ProfilePageData.birthDateTitle(archiveType: .family)
        XCTAssertNotEqual(result, ProfilePageData.birthDateTitle(archiveType: .person))
    }

    func testBirthDateTitle_Organization_MatchesFamily() {
        XCTAssertEqual(
            ProfilePageData.birthDateTitle(archiveType: .organization),
            ProfilePageData.birthDateTitle(archiveType: .family)
        )
    }

    // MARK: - birthLocationTitle

    func testBirthLocationTitle_Person_ReturnsBirthLocation() {
        let result = ProfilePageData.birthLocationTitle(archiveType: .person)
        XCTAssertFalse(result.isEmpty)
    }

    func testBirthLocationTitle_Family_ReturnsLocationEstablished() {
        let result = ProfilePageData.birthLocationTitle(archiveType: .family)
        XCTAssertNotEqual(result, ProfilePageData.birthLocationTitle(archiveType: .person))
    }

    // MARK: - Milestone Titles

    func testMilestoneTitle_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneTitle().isEmpty)
    }

    func testMilestoneStartDate_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneStartDate().isEmpty)
    }

    func testMilestoneEndDate_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneEndDate().isEmpty)
    }

    func testMilestoneDescription_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneDescription().isEmpty)
    }

    func testMilestoneLocation_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneLocation().isEmpty)
    }

    // MARK: - Name Hints

    func testNameHint_Person_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.nameHint(archiveType: .person).isEmpty)
    }

    func testNameHint_Family_DiffersFromPerson() {
        XCTAssertNotEqual(
            ProfilePageData.nameHint(archiveType: .family),
            ProfilePageData.nameHint(archiveType: .person)
        )
    }

    func testNameHint_Organization_DiffersFromPerson() {
        XCTAssertNotEqual(
            ProfilePageData.nameHint(archiveType: .organization),
            ProfilePageData.nameHint(archiveType: .person)
        )
    }

    func testNameHint_Community_DiffersFromOrganization() {
        XCTAssertNotEqual(
            ProfilePageData.nameHint(archiveType: .community),
            ProfilePageData.nameHint(archiveType: .organization)
        )
    }

    func testNameHint_NonProfit_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.nameHint(archiveType: .nonProfit).isEmpty)
    }

    // MARK: - NickName Hints

    func testNickNameHint_Person_MatchesNickNameTitle() {
        XCTAssertEqual(
            ProfilePageData.nickNameHint(archiveType: .person),
            ProfilePageData.nickNameTitle(archiveType: .person)
        )
    }

    func testNickNameHint_Family_MatchesFamilyTitle() {
        XCTAssertEqual(
            ProfilePageData.nickNameHint(archiveType: .family),
            ProfilePageData.nickNameTitle(archiveType: .family)
        )
    }

    // MARK: - Gender Hints

    func testGenderHint_Person_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.genderHint(archiveType: .person).isEmpty)
    }

    func testGenderHint_Family_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderHint(archiveType: .family).isEmpty)
    }

    func testGenderHint_Organization_ReturnsEmpty() {
        XCTAssertTrue(ProfilePageData.genderHint(archiveType: .organization).isEmpty)
    }

    // MARK: - Birth Date Hints

    func testBirthDateHint_AllTypes_ReturnYYYYMMDD() {
        for archiveType in ArchiveType.allCases {
            let hint = ProfilePageData.birthDateHint(archiveType: archiveType)
            XCTAssertEqual(hint, "YYYY-MM-DD", "birthDateHint should return YYYY-MM-DD for \(archiveType)")
        }
    }

    // MARK: - Birth Location Hints

    func testBirthLocationHint_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.birthLocationHint(archiveType: .person).isEmpty)
    }

    func testBirthLocationHint_AllTypes_ReturnSameValue() {
        let personHint = ProfilePageData.birthLocationHint(archiveType: .person)
        for archiveType in ArchiveType.allCases {
            XCTAssertEqual(
                ProfilePageData.birthLocationHint(archiveType: archiveType),
                personHint,
                "All archive types should return the same birthLocationHint"
            )
        }
    }

    // MARK: - Milestone Hints

    func testMilestoneTitleHint_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneTitleHint().isEmpty)
    }

    func testMilestoneStartDateHint_ReturnsYYYYMMDD() {
        XCTAssertFalse(ProfilePageData.milestoneStartDateHint().isEmpty)
    }

    func testMilestoneEndDateHint_MatchesStartDateHint() {
        XCTAssertEqual(
            ProfilePageData.milestoneEndDateHint(),
            ProfilePageData.milestoneStartDateHint()
        )
    }

    func testMilestoneDescriptionHint_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneDescriptionHint().isEmpty)
    }

    func testMilestoneLocationHint_ReturnsNonEmpty() {
        XCTAssertFalse(ProfilePageData.milestoneLocationHint().isEmpty)
    }

    // MARK: - Consistency: All ArchiveType cases covered

    func testAllArchiveTypes_NameTitle_ReturnsNonEmpty() {
        for archiveType in ArchiveType.allCases {
            XCTAssertFalse(
                ProfilePageData.nameTitle(archiveType: archiveType).isEmpty,
                "nameTitle should not be empty for \(archiveType)"
            )
        }
    }

    func testAllArchiveTypes_NickNameTitle_ReturnsNonEmpty() {
        for archiveType in ArchiveType.allCases {
            XCTAssertFalse(
                ProfilePageData.nickNameTitle(archiveType: archiveType).isEmpty,
                "nickNameTitle should not be empty for \(archiveType)"
            )
        }
    }

    func testAllArchiveTypes_BirthDateTitle_ReturnsNonEmpty() {
        for archiveType in ArchiveType.allCases {
            XCTAssertFalse(
                ProfilePageData.birthDateTitle(archiveType: archiveType).isEmpty,
                "birthDateTitle should not be empty for \(archiveType)"
            )
        }
    }

    func testAllArchiveTypes_BirthLocationTitle_ReturnsNonEmpty() {
        for archiveType in ArchiveType.allCases {
            XCTAssertFalse(
                ProfilePageData.birthLocationTitle(archiveType: archiveType).isEmpty,
                "birthLocationTitle should not be empty for \(archiveType)"
            )
        }
    }
}
