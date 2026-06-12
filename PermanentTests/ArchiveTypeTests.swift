//
//  ArchiveTypeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ArchiveTypeTests: XCTestCase {

    // MARK: - CaseIterable

    func testAllCases_Has9Cases() {
        XCTAssertEqual(ArchiveType.allCases.count, 9)
    }

    // MARK: - rawValue

    func testRawValue_Person() {
        XCTAssertEqual(ArchiveType.person.rawValue, "type.archive.person")
    }

    func testRawValue_Individual_MatchesPerson() {
        XCTAssertEqual(ArchiveType.individual.rawValue, ArchiveType.person.rawValue)
    }

    func testRawValue_Other_MatchesPerson() {
        XCTAssertEqual(ArchiveType.other.rawValue, ArchiveType.person.rawValue)
    }

    func testRawValue_Unsure_MatchesPerson() {
        XCTAssertEqual(ArchiveType.unsure.rawValue, ArchiveType.person.rawValue)
    }

    func testRawValue_Family() {
        XCTAssertEqual(ArchiveType.family.rawValue, "type.archive.family")
    }

    func testRawValue_FamilyHistory_MatchesFamily() {
        XCTAssertEqual(ArchiveType.familyHistory.rawValue, ArchiveType.family.rawValue)
    }

    func testRawValue_Organization() {
        XCTAssertEqual(ArchiveType.organization.rawValue, "type.archive.organization")
    }

    func testRawValue_Community_MatchesOrganization() {
        XCTAssertEqual(ArchiveType.community.rawValue, ArchiveType.organization.rawValue)
    }

    func testRawValue_NonProfit() {
        XCTAssertEqual(ArchiveType.nonProfit.rawValue, "type.archive.nonprofit")
    }

    // MARK: - archiveTypeName

    func testArchiveTypeName_PersonGroup() {
        let types: [ArchiveType] = [.person, .individual, .other, .unsure]
        for type in types {
            XCTAssertEqual(type.archiveTypeName, ArchiveType.person.archiveTypeName, "\(type) should match person")
        }
    }

    func testArchiveTypeName_FamilyGroup() {
        XCTAssertEqual(ArchiveType.family.archiveTypeName, ArchiveType.familyHistory.archiveTypeName)
    }

    func testArchiveTypeName_OrganizationGroup() {
        XCTAssertEqual(ArchiveType.organization.archiveTypeName, ArchiveType.community.archiveTypeName)
    }

    func testArchiveTypeName_AllNonEmpty() {
        for type in ArchiveType.allCases {
            XCTAssertFalse(type.archiveTypeName.isEmpty, "\(type) archiveTypeName should not be empty")
        }
    }

    func testArchiveTypeName_FourDistinctGroups() {
        let names = Set(ArchiveType.allCases.map { $0.archiveTypeName })
        XCTAssertEqual(names.count, 4)
    }

    // MARK: - create(localizedValue:)

    func testCreate_Person() {
        let result = ArchiveType.create(localizedValue: ArchiveType.person.archiveTypeName)
        XCTAssertEqual(result, .person)
    }

    func testCreate_Family() {
        let result = ArchiveType.create(localizedValue: ArchiveType.family.archiveTypeName)
        XCTAssertEqual(result, .family)
    }

    func testCreate_Organization() {
        let result = ArchiveType.create(localizedValue: ArchiveType.organization.archiveTypeName)
        XCTAssertEqual(result, .organization)
    }

    func testCreate_NonProfit() {
        let result = ArchiveType.create(localizedValue: ArchiveType.nonProfit.archiveTypeName)
        XCTAssertEqual(result, .nonProfit)
    }

    func testCreate_InvalidValue_ReturnsNil() {
        XCTAssertNil(ArchiveType.create(localizedValue: "InvalidType"))
    }

    func testCreate_EmptyString_ReturnsNil() {
        XCTAssertNil(ArchiveType.create(localizedValue: ""))
    }

    // MARK: - byRawValue

    func testByRawValue_Person() {
        XCTAssertEqual(ArchiveType.byRawValue("type.archive.person"), .person)
    }

    func testByRawValue_Family() {
        XCTAssertEqual(ArchiveType.byRawValue("type.archive.family"), .family)
    }

    func testByRawValue_Organization() {
        XCTAssertEqual(ArchiveType.byRawValue("type.archive.organization"), .organization)
    }

    func testByRawValue_Unknown_DefaultsToPerson() {
        XCTAssertEqual(ArchiveType.byRawValue("unknown"), .person)
    }

    func testByRawValue_Empty_DefaultsToPerson() {
        XCTAssertEqual(ArchiveType.byRawValue(""), .person)
    }

    func testByRawValue_Nonprofit_DefaultsToPerson() {
        XCTAssertEqual(ArchiveType.byRawValue("type.archive.nonprofit"), .person)
    }

    // MARK: - personalInformationPublicPageTitle

    func testPersonalInfoTitle_PersonGroup_Match() {
        let types: [ArchiveType] = [.person, .individual, .other, .unsure]
        let expected = ArchiveType.person.personalInformationPublicPageTitle
        for type in types {
            XCTAssertEqual(type.personalInformationPublicPageTitle, expected, "\(type) should match person")
        }
    }

    func testPersonalInfoTitle_FamilyGroup_Match() {
        XCTAssertEqual(ArchiveType.family.personalInformationPublicPageTitle, ArchiveType.familyHistory.personalInformationPublicPageTitle)
    }

    func testPersonalInfoTitle_OrganizationGroup_Match() {
        XCTAssertEqual(ArchiveType.organization.personalInformationPublicPageTitle, ArchiveType.community.personalInformationPublicPageTitle)
    }

    func testPersonalInfoTitle_AllDistinct() {
        let titles = Set([
            ArchiveType.person.personalInformationPublicPageTitle,
            ArchiveType.family.personalInformationPublicPageTitle,
            ArchiveType.organization.personalInformationPublicPageTitle,
            ArchiveType.nonProfit.personalInformationPublicPageTitle
        ])
        XCTAssertEqual(titles.count, 4)
    }

    // MARK: - longDescriptionHint

    func testLongDescriptionHint_PersonGroup_Match() {
        let types: [ArchiveType] = [.person, .individual, .other, .unsure]
        let expected = ArchiveType.person.longDescriptionHint
        for type in types {
            XCTAssertEqual(type.longDescriptionHint, expected, "\(type) should match person")
        }
    }

    func testLongDescriptionHint_FamilyGroup_Match() {
        XCTAssertEqual(ArchiveType.family.longDescriptionHint, ArchiveType.familyHistory.longDescriptionHint)
    }

    func testLongDescriptionHint_AllNonEmpty() {
        for type in ArchiveType.allCases {
            XCTAssertFalse(type.longDescriptionHint.isEmpty, "\(type) longDescriptionHint should not be empty")
        }
    }

    // MARK: - onboardingType

    func testOnboardingType_AllUnique() {
        let types = ArchiveType.allCases.map { $0.onboardingType }
        XCTAssertEqual(Set(types).count, 9, "All onboardingType values should be unique")
    }

    func testOnboardingType_AllNonEmpty() {
        for type in ArchiveType.allCases {
            XCTAssertFalse(type.onboardingType.isEmpty)
        }
    }

    func testOnboardingType_Person() {
        XCTAssertEqual(ArchiveType.person.onboardingType, "Personal")
    }

    func testOnboardingType_Family() {
        XCTAssertEqual(ArchiveType.family.onboardingType, "Family")
    }

    func testOnboardingType_Organization() {
        XCTAssertEqual(ArchiveType.organization.onboardingType, "Organization")
    }

    func testOnboardingType_NonProfit() {
        XCTAssertEqual(ArchiveType.nonProfit.onboardingType, "Nonprofit Organization")
    }

    // MARK: - onboardingDescription

    func testOnboardingDescription_AllNonEmpty() {
        for type in ArchiveType.allCases {
            XCTAssertFalse(type.onboardingDescription.isEmpty)
        }
    }

    func testOnboardingDescription_AllUnique() {
        let descriptions = ArchiveType.allCases.map { $0.onboardingDescription }
        XCTAssertEqual(Set(descriptions).count, 9)
    }

    // MARK: - tag

    func testTag_AllNonEmpty() {
        for type in ArchiveType.allCases {
            XCTAssertFalse(type.tag.isEmpty)
            XCTAssertTrue(type.tag.hasPrefix("type:"))
        }
    }

    func testTag_Person() {
        XCTAssertEqual(ArchiveType.person.tag, "type:myself")
    }

    func testTag_Family() {
        XCTAssertEqual(ArchiveType.family.tag, "type:family")
    }

    func testTag_Organization() {
        XCTAssertEqual(ArchiveType.organization.tag, "type:org")
    }

    func testTag_Unsure() {
        XCTAssertEqual(ArchiveType.unsure.tag, "type:unsure")
    }

    // MARK: - Identifiable

    func testId_EqualsRawValue() {
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }

    // MARK: - Shared computed properties

    func testAboutPublicPageTitle_SameForAll() {
        let expected = ArchiveType.person.aboutPublicPageTitle
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.aboutPublicPageTitle, expected)
        }
    }

    func testShortDescriptionTitle_SameForAll() {
        let expected = ArchiveType.person.shortDescriptionTitle
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.shortDescriptionTitle, expected)
        }
    }

    func testShortDescriptionHint_SameForAll() {
        let expected = ArchiveType.person.shortDescriptionHint
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.shortDescriptionHint, expected)
        }
    }

    func testLongDescriptionTitle_SameForAll() {
        let expected = ArchiveType.person.longDescriptionTitle
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.longDescriptionTitle, expected)
        }
    }

    func testMilestoneTitleHint_SameForAll() {
        let expected = ArchiveType.person.milestoneTitleHint
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.milestoneTitleHint, expected)
        }
    }

    func testMilestoneLocationHint_SameForAll() {
        let expected = ArchiveType.person.milestoneLocationLabelHint
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.milestoneLocationLabelHint, expected)
        }
    }

    func testMilestoneDateHint_SameForAll() {
        let expected = ArchiveType.person.milestoneDateLabelHint
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.milestoneDateLabelHint, expected)
        }
    }

    func testMilestoneDescriptionHint_SameForAll() {
        let expected = ArchiveType.person.milestoneDescriptionTextHint
        for type in ArchiveType.allCases {
            XCTAssertEqual(type.milestoneDescriptionTextHint, expected)
        }
    }
}
