//
//  ShareFindArchiveByEmailViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 08.05.2026.
//

import XCTest
import Combine
@testable import Permanent

@MainActor
final class ShareFindArchiveByEmailViewModelTests: XCTestCase {
    private var sut: ShareFindArchiveByEmailViewModel!

    override func setUp() {
        super.setUp()
        sut = ShareFindArchiveByEmailViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "")
    }

    func testInitialState_SubmittedSearchEmailIsNil() {
        XCTAssertNil(sut.submittedSearchEmail)
    }

    func testInitialState_IsSearchingIsFalse() {
        XCTAssertFalse(sut.isSearching)
    }

    func testInitialState_SearchOutcomeIsIdle() {
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected searchOutcome to be .idle, got \(sut.searchOutcome)")
        }
    }

    func testInitialState_VisibleSearchOutcomeIsIdle() {
        if case .idle = sut.visibleSearchOutcome {
        } else {
            XCTFail("Expected visibleSearchOutcome to be .idle")
        }
    }

    func testInitialState_VisibleOutcomeStateIsZero() {
        XCTAssertEqual(sut.visibleOutcomeState, 0)
    }

    // MARK: - performSearch() Validation

    func testPerformSearch_EmptyText_ReturnsFalse() {
        sut.searchText = ""
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_InvalidEmail_ReturnsFalse() {
        sut.searchText = "not-an-email"
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_InvalidEmail_SubmittedSearchEmailStaysNil() {
        sut.searchText = "bad-email"
        sut.performSearch()
        XCTAssertNil(sut.submittedSearchEmail)
    }

    func testPerformSearch_InvalidEmail_SearchOutcomeStaysIdle() {
        sut.searchText = "nope"
        sut.performSearch()
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle after invalid email search")
        }
    }

    func testPerformSearch_WhitespaceOnlyEmail_ReturnsFalse() {
        sut.searchText = "   "
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_ValidEmail_ReturnsTrue() {
        sut.searchText = "user@example.com"
        XCTAssertTrue(sut.performSearch())
    }

    func testPerformSearch_ValidEmail_SetsSubmittedSearchEmail() {
        sut.searchText = "User@Example.COM"
        sut.performSearch()
        XCTAssertEqual(sut.submittedSearchEmail, "user@example.com")
    }

    func testPerformSearch_ValidEmail_SetsIsSearchingTrue() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        XCTAssertTrue(sut.isSearching)
    }

    func testPerformSearch_ValidEmail_SetsSearchOutcomeToIdle() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle during search")
        }
    }

    func testPerformSearch_EmailWithLeadingTrailingSpaces_TrimsAndValidates() {
        sut.searchText = "  user@example.com  "
        XCTAssertTrue(sut.performSearch())
        XCTAssertEqual(sut.submittedSearchEmail, "user@example.com")
    }

    func testPerformSearch_EmailWithZeroWidthCharacters_SanitizesAndSearches() {
        sut.searchText = "user\u{200B}@example.com"
        XCTAssertTrue(sut.performSearch())
        XCTAssertEqual(sut.submittedSearchEmail, "user@example.com")
    }

    func testPerformSearch_EmailWithMultipleZeroWidthChars_SanitizesAll() {
        sut.searchText = "\u{200C}user\u{200D}@\u{2060}example\u{FEFF}.com"
        XCTAssertTrue(sut.performSearch())
        XCTAssertEqual(sut.submittedSearchEmail, "user@example.com")
    }

    func testPerformSearch_EmailMissingAtSign_ReturnsFalse() {
        sut.searchText = "userexample.com"
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_EmailMissingDomain_ReturnsFalse() {
        sut.searchText = "user@"
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_EmailMissingLocalPart_ReturnsFalse() {
        sut.searchText = "@example.com"
        XCTAssertFalse(sut.performSearch())
    }

    func testPerformSearch_ValidEmailWithPlusTag_ReturnsTrue() {
        sut.searchText = "user+tag@example.com"
        XCTAssertTrue(sut.performSearch())
    }

    func testPerformSearch_ValidEmailWithDots_ReturnsTrue() {
        sut.searchText = "first.last@example.co.uk"
        XCTAssertTrue(sut.performSearch())
    }

    // MARK: - clearSearch()

    func testClearSearch_ResetsSearchText() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        sut.clearSearch()
        XCTAssertEqual(sut.searchText, "")
    }

    func testClearSearch_ResetsSubmittedSearchEmail() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        sut.clearSearch()
        XCTAssertNil(sut.submittedSearchEmail)
    }

    func testClearSearch_ResetsIsSearching() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        sut.clearSearch()
        XCTAssertFalse(sut.isSearching)
    }

    func testClearSearch_ResetsSearchOutcomeToIdle() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        sut.clearSearch()
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle after clearSearch")
        }
    }

    // MARK: - reset()

    func testReset_ResetsAllState() {
        sut.searchText = "test@test.com"
        sut.performSearch()
        sut.reset()

        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.submittedSearchEmail)
        XCTAssertFalse(sut.isSearching)
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle after reset")
        }
    }

    func testReset_CalledWithoutPriorSearch_StaysInInitialState() {
        sut.reset()
        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.submittedSearchEmail)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - handleTextChanged()

    func testHandleTextChanged_WhenSubmittedEmailIsNil_DoesNotCrash() {
        sut.searchText = "something"
        sut.handleTextChanged()
        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle")
        }
    }

    func testHandleTextChanged_WhenSubmittedEmailExists_SetsOutcomeToIdle() {
        sut.searchText = "test@test.com"
        sut.performSearch()

        sut.searchText = "different@test.com"
        sut.handleTextChanged()

        if case .idle = sut.searchOutcome {
        } else {
            XCTFail("Expected .idle after text changed with existing submitted email")
        }
    }

    // MARK: - visibleSearchOutcome

    func testVisibleSearchOutcome_WhenSubmittedEmailIsNil_ReturnsIdle() {
        sut.searchText = "anything"
        if case .idle = sut.visibleSearchOutcome {
        } else {
            XCTFail("Expected .idle when submittedSearchEmail is nil")
        }
    }

    func testVisibleSearchOutcome_WhenSearchTextDiffersFromSubmitted_ReturnsIdle() {
        sut.searchText = "user@example.com"
        sut.performSearch()

        sut.searchText = "other@example.com"

        if case .idle = sut.visibleSearchOutcome {
        } else {
            XCTFail("Expected .idle when searchText differs from submitted email")
        }
    }

    func testVisibleSearchOutcome_WhenSearchTextMatchesSubmitted_ReturnsActualOutcome() {
        sut.searchText = "user@example.com"
        sut.performSearch()

        if case .idle = sut.visibleSearchOutcome {
        } else {
            XCTFail("Expected .idle while search is in progress")
        }
    }

    // MARK: - visibleOutcomeState

    func testVisibleOutcomeState_IdleReturnsZero() {
        XCTAssertEqual(sut.visibleOutcomeState, 0)
    }

    func testVisibleOutcomeState_AfterInvalidSearch_ReturnsZero() {
        sut.searchText = "bad"
        sut.performSearch()
        XCTAssertEqual(sut.visibleOutcomeState, 0)
    }

    // MARK: - performSearch() Consecutive Calls

    func testPerformSearch_CalledTwice_UpdatesSubmittedEmail() {
        sut.searchText = "first@example.com"
        sut.performSearch()
        XCTAssertEqual(sut.submittedSearchEmail, "first@example.com")

        sut.searchText = "second@example.com"
        sut.performSearch()
        XCTAssertEqual(sut.submittedSearchEmail, "second@example.com")
    }

    func testPerformSearch_SameEmailTwice_StillReturnsTrue() {
        sut.searchText = "test@example.com"
        XCTAssertTrue(sut.performSearch())
        sut.clearSearch()

        sut.searchText = "test@example.com"
        XCTAssertTrue(sut.performSearch())
    }

    func testPerformSearch_InvalidThenValid_SecondCallSucceeds() {
        sut.searchText = "invalid"
        XCTAssertFalse(sut.performSearch())
        XCTAssertNil(sut.submittedSearchEmail)

        sut.searchText = "valid@test.com"
        XCTAssertTrue(sut.performSearch())
        XCTAssertEqual(sut.submittedSearchEmail, "valid@test.com")
    }

    func testPerformSearch_ValidThenInvalid_InvalidClearsSubmittedEmail() {
        sut.searchText = "valid@test.com"
        sut.performSearch()
        XCTAssertNotNil(sut.submittedSearchEmail)

        sut.searchText = "invalid"
        sut.performSearch()
        XCTAssertNil(sut.submittedSearchEmail)
    }

    // MARK: - clearSearch() After Various States

    func testClearSearch_AfterInvalidSearch_ResetsCleanly() {
        sut.searchText = "bad"
        sut.performSearch()
        sut.clearSearch()

        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.submittedSearchEmail)
        XCTAssertFalse(sut.isSearching)
    }

    func testClearSearch_CalledMultipleTimes_DoesNotCrash() {
        sut.clearSearch()
        sut.clearSearch()
        XCTAssertEqual(sut.searchText, "")
    }

    // MARK: - Case Normalization

    func testPerformSearch_MixedCaseEmail_NormalizesToLowercase() {
        sut.searchText = "User.Name@EXAMPLE.Com"
        sut.performSearch()
        XCTAssertEqual(sut.submittedSearchEmail, "user.name@example.com")
    }

    func testPerformSearch_AllUppercaseEmail_NormalizesToLowercase() {
        sut.searchText = "TEST@TEST.COM"
        sut.performSearch()
        XCTAssertEqual(sut.submittedSearchEmail, "test@test.com")
    }

    // MARK: - API Result Integration (Async)

    func testPerformSearch_ValidEmail_EventuallyCompletesSearch() {
        sut.searchText = "nonexistent-test-user-xyz@permanent.org"
        sut.performSearch()
        XCTAssertTrue(sut.isSearching)

        let expectation = XCTestExpectation(description: "Search completes")
        let cancellable = sut.$isSearching
            .dropFirst()
            .filter { !$0 }
            .sink { _ in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 10)
        cancellable.cancel()

        XCTAssertFalse(sut.isSearching)
        switch sut.searchOutcome {
        case .noAccount(let email):
            XCTAssertEqual(email, "nonexistent-test-user-xyz@permanent.org")
        case .found:
            break
        case .idle:
            XCTFail("Expected a result after search completes, got .idle")
        }
    }

    func testPerformSearch_ClearWhileSearching_ResetsState() {
        sut.searchText = "user@example.com"
        sut.performSearch()
        XCTAssertTrue(sut.isSearching)

        sut.clearSearch()
        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.submittedSearchEmail)
        XCTAssertFalse(sut.isSearching)
    }

    func testPerformSearch_ResetWhileSearching_ResetsState() {
        sut.searchText = "user@example.com"
        sut.performSearch()
        XCTAssertTrue(sut.isSearching)

        sut.reset()
        XCTAssertEqual(sut.searchText, "")
        XCTAssertNil(sut.submittedSearchEmail)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - ArchiveResult Struct

    func testArchiveResult_HasUniqueIds() {
        let a = ShareFindArchiveByEmailViewModel.ArchiveResult(
            archiveID: 1, initials: "AB", name: "Test", thumbnailURL: nil
        )
        let b = ShareFindArchiveByEmailViewModel.ArchiveResult(
            archiveID: 1, initials: "AB", name: "Test", thumbnailURL: nil
        )
        XCTAssertNotEqual(a.id, b.id)
    }

    func testArchiveResult_StoresAllProperties() {
        let result = ShareFindArchiveByEmailViewModel.ArchiveResult(
            archiveID: 42,
            initials: "JD",
            name: "The John Doe Archive",
            thumbnailURL: "https://example.com/thumb.jpg"
        )
        XCTAssertEqual(result.archiveID, 42)
        XCTAssertEqual(result.initials, "JD")
        XCTAssertEqual(result.name, "The John Doe Archive")
        XCTAssertEqual(result.thumbnailURL, "https://example.com/thumb.jpg")
    }

    func testArchiveResult_NilArchiveID() {
        let result = ShareFindArchiveByEmailViewModel.ArchiveResult(
            archiveID: nil, initials: "XX", name: "Test", thumbnailURL: nil
        )
        XCTAssertNil(result.archiveID)
    }

    func testArchiveResult_NilThumbnailURL() {
        let result = ShareFindArchiveByEmailViewModel.ArchiveResult(
            archiveID: 1, initials: "XX", name: "Test", thumbnailURL: nil
        )
        XCTAssertNil(result.thumbnailURL)
    }

    // MARK: - SearchOutcome Enum

    func testSearchOutcome_FoundContainsArchives() {
        let archives = [
            ShareFindArchiveByEmailViewModel.ArchiveResult(
                archiveID: 1, initials: "AB", name: "Test", thumbnailURL: nil
            )
        ]
        let outcome = ShareFindArchiveByEmailViewModel.SearchOutcome.found(archives)
        if case .found(let results) = outcome {
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results[0].name, "Test")
        } else {
            XCTFail("Expected .found")
        }
    }

    func testSearchOutcome_NoAccountContainsEmail() {
        let outcome = ShareFindArchiveByEmailViewModel.SearchOutcome.noAccount("user@test.com")
        if case .noAccount(let email) = outcome {
            XCTAssertEqual(email, "user@test.com")
        } else {
            XCTFail("Expected .noAccount")
        }
    }
}
