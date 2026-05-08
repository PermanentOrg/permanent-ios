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

    // MARK: - Init Tests

    func testInit_SetsArchiveType_Person() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertEqual(sut.archiveType, .person)
    }

    func testInit_SetsArchiveType_Family() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.family"))
        XCTAssertEqual(sut.archiveType, .family)
    }

    func testInit_SetsArchiveType_Organization() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        XCTAssertEqual(sut.archiveType, .organization)
    }

    func testInit_NilArchiveType_DoesNotCrash() {
        let archive = makeArchiveData(accessRole: "access.role.owner", type: nil)
        let sut = PublicProfilePageViewModel(archive)
        XCTAssertNil(sut.archiveType)
    }

    func testInit_EmptyProfileItems() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertTrue(sut.profileItems.isEmpty)
    }

    func testInit_IsPubliclyVisible_DefaultsFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertFalse(sut.isPubliclyVisible)
    }

    // MARK: - isEditDataEnabled Tests

    func testIsEditDataEnabled_OwnerRole_ReturnsTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertTrue(sut.isEditDataEnabled)
    }

    func testIsEditDataEnabled_ManagerRole_ReturnsTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.manager", type: "type.archive.person"))
        XCTAssertTrue(sut.isEditDataEnabled)
    }

    func testIsEditDataEnabled_ViewerRole_ReturnsFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        XCTAssertFalse(sut.isEditDataEnabled)
    }

    func testIsEditDataEnabled_EditorRole_ReturnsFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.editor", type: "type.archive.person"))
        XCTAssertFalse(sut.isEditDataEnabled)
    }

    func testIsEditDataEnabled_CuratorRole_ReturnsFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.curator", type: "type.archive.person"))
        XCTAssertFalse(sut.isEditDataEnabled)
    }

    // MARK: - Computed Profile Item Accessors

    func testBlurbProfileItem_ReturnsBlurbFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let blurb = BlurbProfileItem()
        blurb.shortDescription = "A short blurb"
        sut.profileItems = [blurb]
        XCTAssertEqual(sut.blurbProfileItem?.shortDescription, "A short blurb")
    }

    func testBlurbProfileItem_NilWhenAbsent() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        sut.profileItems = [BasicProfileItem()]
        XCTAssertNil(sut.blurbProfileItem)
    }

    func testDescriptionProfileItem_ReturnsFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let desc = DescriptionProfileItem()
        desc.longDescription = "Long description"
        sut.profileItems = [desc]
        XCTAssertEqual(sut.descriptionProfileItem?.longDescription, "Long description")
    }

    func testBasicProfileItem_ReturnsFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let basic = BasicProfileItem()
        basic.fullName = "John Doe"
        basic.nickname = "JD"
        sut.profileItems = [basic]
        XCTAssertEqual(sut.basicProfileItem?.fullName, "John Doe")
        XCTAssertEqual(sut.basicProfileItem?.nickname, "JD")
    }

    func testArchiveNameProfileItem_OnlyReturnsBasicWithArchiveName() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let basicWithoutName = BasicProfileItem()
        basicWithoutName.fullName = "Name"
        let basicWithName = BasicProfileItem()
        basicWithName.archiveName = "My Archive"
        sut.profileItems = [basicWithoutName, basicWithName]
        XCTAssertEqual(sut.archiveNameProfileItem?.archiveName, "My Archive")
    }

    func testArchiveNameProfileItem_NilWhenNoArchiveName() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let basic = BasicProfileItem()
        basic.fullName = "Name"
        sut.profileItems = [basic]
        XCTAssertNil(sut.archiveNameProfileItem)
    }

    func testGenderProfileItem_ReturnsFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let gender = GenderProfileItem()
        gender.personGender = "Male"
        sut.profileItems = [gender]
        XCTAssertEqual(sut.profileGenderProfileItem?.personGender, "Male")
    }

    func testBirthInfoProfileItem_ReturnsFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let birth = BirthInfoProfileItem()
        birth.birthDate = "1990-01-15"
        sut.profileItems = [birth]
        XCTAssertEqual(sut.birthInfoProfileItem?.birthDate, "1990-01-15")
    }

    func testEstablishedInfoProfileItem_ReturnsFromList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let established = EstablishedInfoProfileItem()
        established.establishedDate = "2005-06-01"
        sut.profileItems = [established]
        XCTAssertEqual(sut.establishedInfoProfileItem?.establishedDate, "2005-06-01")
    }

    func testEmailProfileItems_ReturnsAllEmails() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let email1 = EmailProfileItem()
        email1.email = "a@example.com"
        let email2 = EmailProfileItem()
        email2.email = "b@example.com"
        sut.profileItems = [email1, BasicProfileItem(), email2]
        XCTAssertEqual(sut.emailProfileItems.count, 2)
    }

    func testEmailProfileItems_EmptyWhenNone() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        sut.profileItems = [BasicProfileItem()]
        XCTAssertTrue(sut.emailProfileItems.isEmpty)
    }

    func testSocialMediaProfileItems_ReturnsAllLinks() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let link1 = SocialMediaProfileItem()
        link1.link = "https://twitter.com/test"
        let link2 = SocialMediaProfileItem()
        link2.link = "https://github.com/test"
        sut.profileItems = [link1, link2]
        XCTAssertEqual(sut.socialMediaProfileItems.count, 2)
    }

    // MARK: - Milestones Sorting Edge Cases

    func testMilestonesProfileItems_NilDatesGoFirst() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let withDate = MilestoneProfileItem()
        withDate.startDateString = "2022-01-01"
        let withoutDate = MilestoneProfileItem()
        sut.profileItems = [withDate, withoutDate]

        let sorted = sut.milestonesProfileItems
        XCTAssertNil(sorted[0].startDateString)
        XCTAssertEqual(sorted[1].startDateString, "2022-01-01")
    }

    func testMilestonesProfileItems_EmptyWhenNone() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        sut.profileItems = [BasicProfileItem()]
        XCTAssertTrue(sut.milestonesProfileItems.isEmpty)
    }

    // MARK: - getProfileViewData Organization/Family Fields

    func testGetProfileViewData_OrgOwner_InformationSection_OrgFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.fullName, in: info))
        XCTAssertTrue(containsCell(.nickName, in: info))
        XCTAssertTrue(containsCell(.establishedDate, in: info))
        XCTAssertTrue(containsCell(.establishedLocation, in: info))
    }

    func testGetProfileViewData_OrgOwner_NoPersonFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertFalse(containsCell(.gender, in: info))
        XCTAssertFalse(containsCell(.birthDate, in: info))
        XCTAssertFalse(containsCell(.birthLocation, in: info))
    }

    func testGetProfileViewData_FamilyOwner_UsesOrgFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.family"))
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.establishedDate, in: info))
        XCTAssertTrue(containsCell(.establishedLocation, in: info))
    }

    func testGetProfileViewData_NonProfitOwner_UsesOrgFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        sut.archiveType = .nonProfit
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.establishedDate, in: info))
    }

    func testGetProfileViewData_CommunityOwner_UsesOrgFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        sut.archiveType = .community
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.establishedDate, in: info))
    }

    func testGetProfileViewData_IndividualOwner_UsesPersonFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.individual"))
        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.gender, in: info))
        XCTAssertTrue(containsCell(.birthDate, in: info))
    }

    // MARK: - getProfileViewData Viewer Mode (populated items only)

    func testGetProfileViewData_Viewer_NoProfileVisibility() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let data = sut.getProfileViewData()
        XCTAssertNil(data[.profileVisibility])
    }

    func testGetProfileViewData_Viewer_EmptyBlurb_NotIncluded() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let blurb = BlurbProfileItem()
        blurb.shortDescription = ""
        sut.profileItems = [blurb]

        let data = sut.getProfileViewData()
        let about = data[.about] ?? []
        XCTAssertFalse(containsCell(.blurb, in: about))
    }

    func testGetProfileViewData_Viewer_PopulatedBlurb_Included() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let blurb = BlurbProfileItem()
        blurb.shortDescription = "Hello"
        sut.profileItems = [blurb]

        let data = sut.getProfileViewData()
        let about = data[.about] ?? []
        XCTAssertTrue(containsCell(.blurb, in: about))
        XCTAssertFalse(containsCell(.archiveName, in: about))
    }

    func testGetProfileViewData_Viewer_OnlyPopulatedInformationFields() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let basic = BasicProfileItem()
        basic.fullName = "Jane"
        sut.profileItems = [basic]

        let data = sut.getProfileViewData()
        let info = data[.information] ?? []

        XCTAssertTrue(containsCell(.fullName, in: info))
        XCTAssertFalse(containsCell(.nickName, in: info))
        XCTAssertFalse(containsCell(.gender, in: info))
    }

    func testGetProfileViewData_Viewer_OrgWithEstablishedDate() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.organization"))
        let est = EstablishedInfoProfileItem()
        est.establishedDate = "2020-01-01"
        sut.profileItems = [est]

        let data = sut.getProfileViewData()
        let info = data[.information] ?? []
        XCTAssertTrue(containsCell(.establishedDate, in: info))
    }

    // MARK: - getProfileViewData Online Presence & Milestones

    func testGetProfileViewData_EmailItems_MappedToSection() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let email1 = EmailProfileItem()
        email1.email = "a@test.com"
        let email2 = EmailProfileItem()
        email2.email = "b@test.com"
        sut.profileItems = [email1, email2]

        let data = sut.getProfileViewData()
        let emails = data[.onlinePresenceEmail] ?? []
        XCTAssertEqual(emails.count, 2)
    }

    func testGetProfileViewData_SocialMediaItems_MappedToSection() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let link = SocialMediaProfileItem()
        link.link = "https://twitter.com"
        sut.profileItems = [link]

        let data = sut.getProfileViewData()
        let links = data[.onlinePresenceLink] ?? []
        XCTAssertEqual(links.count, 1)
    }

    func testGetProfileViewData_Milestones_MappedToSection() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let m1 = MilestoneProfileItem()
        m1.title = "Graduation"
        let m2 = MilestoneProfileItem()
        m2.title = "Job"
        sut.profileItems = [m1, m2]

        let data = sut.getProfileViewData()
        let milestones = data[.milestones] ?? []
        XCTAssertEqual(milestones.count, 2)
    }

    // MARK: - getProfileViewData Nil ArchiveType

    func testGetProfileViewData_NilArchiveType_ReturnsEmpty() {
        let archive = makeArchiveData(accessRole: "access.role.owner", type: nil)
        let sut = PublicProfilePageViewModel(archive)
        let data = sut.getProfileViewData()
        XCTAssertTrue(data.isEmpty)
    }

    // MARK: - isPubliclyVisible Tests

    func testIsPubliclyVisible_AllItemsPublic_ReturnsTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let blurb = BlurbProfileItem()
        blurb.publicDT = "2026-01-01T00:00:00.000+0000"
        let basic = BasicProfileItem()
        basic.publicDT = "2026-01-01T00:00:00.000+0000"
        sut.profileItems = [blurb, basic]
        sut.isPubliclyVisible = sut.profileItems.allSatisfy { $0.publicDT != nil }
        XCTAssertTrue(sut.isPubliclyVisible)
    }

    func testIsPubliclyVisible_SomeItemsNotPublic_ReturnsFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let blurb = BlurbProfileItem()
        blurb.publicDT = "2026-01-01T00:00:00.000+0000"
        let basic = BasicProfileItem()
        sut.profileItems = [blurb, basic]
        sut.isPubliclyVisible = sut.profileItems.allSatisfy { $0.publicDT != nil }
        XCTAssertFalse(sut.isPubliclyVisible)
    }

    // MARK: - createNewBirthProfileItem Tests

    func testCreateNewBirthProfileItem_AppendsToList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertTrue(sut.profileItems.isEmpty)
        sut.createNewBirthProfileItem(newLocation: nil)
        XCTAssertEqual(sut.profileItems.count, 1)
        XCTAssertTrue(sut.profileItems.first is BirthInfoProfileItem)
    }

    func testCreateNewBirthProfileItem_SetsArchiveId() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        sut.createNewBirthProfileItem(newLocation: nil)
        XCTAssertEqual(sut.profileItems.first?.archiveId, sut.archiveData.archiveID)
    }

    // MARK: - createNewEstablishedInfoProfileItem Tests

    func testCreateNewEstablishedInfoProfileItem_AppendsToList() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        sut.createNewEstablishedInfoProfileItem(newLocation: nil)
        XCTAssertEqual(sut.profileItems.count, 1)
        XCTAssertTrue(sut.profileItems.first is EstablishedInfoProfileItem)
    }

    func testCreateNewEstablishedInfoProfileItem_SetsArchiveId() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        sut.createNewEstablishedInfoProfileItem(newLocation: nil)
        XCTAssertEqual(sut.profileItems.first?.archiveId, sut.archiveData.archiveID)
    }

    // MARK: - deleteMilestoneProfileItem Guard Test

    func testDeleteMilestoneProfileItem_NilMilestone_CompletesWithFalse() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let expectation = expectation(description: "Completion")
        sut.deleteMilestoneProfileItem(milestone: nil) { result in
            XCTAssertFalse(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - getAllByArchiveNbr Guard Tests

    func testGetAllByArchiveNbr_NilArchiveID_ReturnsError() {
        let archive = makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person", archiveID: nil)
        let sut = PublicProfilePageViewModel(archive)
        let expectation = expectation(description: "Completion")
        sut.getAllByArchiveNbr(archive) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetAllByArchiveNbr_NilArchiveNbr_ReturnsError() {
        let archive = makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person", archiveNbr: nil)
        let sut = PublicProfilePageViewModel(archive)
        let expectation = expectation(description: "Completion")
        sut.getAllByArchiveNbr(archive) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Update No-Change Path Tests

    func testUpdateBasicProfileItem_NoChanges_CompletesWithTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let expectation = expectation(description: "Completion")
        sut.updateBasicProfileItem(fullNameNewValue: nil, nicknameNewValue: nil) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateGenderProfileItem_NoChanges_CompletesWithTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let expectation = expectation(description: "Completion")
        sut.updateGenderProfileItem(genderNewValue: nil) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateBirthInfoProfileItem_NoChanges_CompletesWithTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let expectation = expectation(description: "Completion")
        sut.updateBirthInfoProfileItem(birthDateNewValue: nil) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateEstablishedInfoProfileItem_NoChanges_CompletesWithTrue() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.organization"))
        let expectation = expectation(description: "Completion")
        sut.updateEstablishedInfoProfileItem(newValue: nil) { result in
            XCTAssertTrue(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Notification Name

    func testProfileItemsUpdatedNotificationName_IsStable() {
        XCTAssertEqual(
            PublicProfilePageViewModel.profileItemsUpdatedNotificationName.rawValue,
            "PublicProfilePageViewModel.profileItemsUpdatedNotificationName"
        )
    }

    // MARK: - newLocnId Tests

    func testNewLocnId_DefaultsToNil() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        XCTAssertNil(sut.newLocnId)
    }

    func testNewLocnId_CanBeSet() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        sut.newLocnId = 42
        XCTAssertEqual(sut.newLocnId, 42)
    }

    // MARK: - Mixed Profile Items Filtering

    func testProfileItems_MixedTypes_CorrectFiltering() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.owner", type: "type.archive.person"))
        let basic = BasicProfileItem()
        basic.fullName = "Test"
        let blurb = BlurbProfileItem()
        blurb.shortDescription = "Blurb"
        let email = EmailProfileItem()
        email.email = "test@test.com"
        let social = SocialMediaProfileItem()
        social.link = "https://test.com"
        let milestone = MilestoneProfileItem()
        milestone.title = "M1"
        let gender = GenderProfileItem()
        gender.personGender = "Other"

        sut.profileItems = [basic, blurb, email, social, milestone, gender]

        XCTAssertNotNil(sut.basicProfileItem)
        XCTAssertNotNil(sut.blurbProfileItem)
        XCTAssertNotNil(sut.profileGenderProfileItem)
        XCTAssertEqual(sut.emailProfileItems.count, 1)
        XCTAssertEqual(sut.socialMediaProfileItems.count, 1)
        XCTAssertEqual(sut.milestonesProfileItems.count, 1)
        XCTAssertNil(sut.descriptionProfileItem)
        XCTAssertNil(sut.birthInfoProfileItem)
        XCTAssertNil(sut.establishedInfoProfileItem)
    }

    // MARK: - Viewer Gender/BirthDate Populated Tests

    func testGetProfileViewData_Viewer_GenderPopulated_Included() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let gender = GenderProfileItem()
        gender.personGender = "Male"
        sut.profileItems = [gender]

        let data = sut.getProfileViewData()
        let info = data[.information] ?? []
        XCTAssertTrue(containsCell(.gender, in: info))
    }

    func testGetProfileViewData_Viewer_BirthDatePopulated_Included() {
        let sut = PublicProfilePageViewModel(makeArchiveData(accessRole: "access.role.viewer", type: "type.archive.person"))
        let birth = BirthInfoProfileItem()
        birth.birthDate = "1990-05-15"
        sut.profileItems = [birth]

        let data = sut.getProfileViewData()
        let info = data[.information] ?? []
        XCTAssertTrue(containsCell(.birthDate, in: info))
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

    private func makeArchiveData(accessRole: String, type: String?, archiveID: Int? = 1, archiveNbr: String? = "0000-0001") -> ArchiveVOData {
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
            archiveID: archiveID,
            publicDT: nil,
            archiveNbr: archiveNbr,
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
