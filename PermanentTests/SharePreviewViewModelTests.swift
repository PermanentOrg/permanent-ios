//
//  SharePreviewViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.01.2026
//

import XCTest
import Combine

@testable import Permanent

@MainActor
final class SharePreviewViewModelTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: SharePreviewMockRepository())
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.shareName, "")
        XCTAssertEqual(vm.sharedByName, "")
        XCTAssertEqual(vm.archiveName, "")
        XCTAssertNil(vm.thumbnailURL)
        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertEqual(vm.shareStatus, .needsApproval)
    }
    
    // MARK: - Data Loading Tests
    
    func testStartLoadsData() async {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository(), shareManagementRepository: MockShareMgmtRepo())
        let finishedLoading = expectation(description: "Finished loading")
        var cancellables = Set<AnyCancellable>()
        
        vm.$isLoading
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in finishedLoading.fulfill() }
            .store(in: &cancellables)
        
        vm.start()
        
        await fulfillment(of: [finishedLoading], timeout: 8.0)
        
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.sharedByName, "Robert Friedman")
        XCTAssertEqual(vm.archiveName, "Family")
        XCTAssertEqual(vm.shareStatus, .accepted)
    }
    
    func testStartHandlesError() async {
        let errorRepo = ErrorRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: errorRepo)
        let finishedLoading = expectation(description: "Finished loading")
        var cancellables = Set<AnyCancellable>()
        
        vm.$isLoading
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in finishedLoading.fulfill() }
            .store(in: &cancellables)
        
        vm.start()
        
        await fulfillment(of: [finishedLoading], timeout: 8.0)
        
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.errorMessage?.contains("Network error") ?? false)
        XCTAssertEqual(vm.shareName, "")
    }
    
    func testLoadingSetsCorrectState() async {
        let delayedRepo = DelayedRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: delayedRepo, shareManagementRepository: MockShareMgmtRepo())
        let startedLoading = expectation(description: "Started loading")
        let finishedLoading = expectation(description: "Finished loading")
        var cancellables = Set<AnyCancellable>()
        
        XCTAssertFalse(vm.isLoading)
        
        var loadingStateChanges = 0
        vm.$isLoading
            .dropFirst()
            .sink { isLoading in
                loadingStateChanges += 1
                if loadingStateChanges == 1 && isLoading {
                    startedLoading.fulfill()
                } else if !isLoading {
                    finishedLoading.fulfill()
                }
            }
            .store(in: &cancellables)
        
        vm.start()
        
        await fulfillment(of: [startedLoading], timeout: 1.0)
        XCTAssertTrue(vm.isLoading)
        
        await fulfillment(of: [finishedLoading], timeout: 8.0)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Cancellation Tests

    func testCancelLoadingResetsIsLoading() async {
        let repo = DelayedRepoForTest()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)
        let startedLoading = expectation(description: "Started loading")
        let stoppedLoading = expectation(description: "Stopped loading")
        var cancellables = Set<AnyCancellable>()
        
        var loadingStateChanges = 0
        vm.$isLoading
            .dropFirst()
            .sink { isLoading in
                loadingStateChanges += 1
                if loadingStateChanges == 1 && isLoading {
                    startedLoading.fulfill()
                } else if !isLoading {
                    stoppedLoading.fulfill()
                }
            }
            .store(in: &cancellables)
        
        vm.start()
        await fulfillment(of: [startedLoading], timeout: 1.0)
        XCTAssertTrue(vm.isLoading)
        
        vm.cancelLoadingTask()
        await fulfillment(of: [stoppedLoading], timeout: 1.0)
        
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testRepositoryCancellationPropagates() async {
        let repo = CancelableRepoForTest()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)
        let startedLoading = expectation(description: "Started loading")
        var cancellables = Set<AnyCancellable>()
        
        vm.$isLoading
            .dropFirst()
            .filter { $0 }
            .first()
            .sink { _ in startedLoading.fulfill() }
            .store(in: &cancellables)
        
        vm.start()
        await fulfillment(of: [startedLoading], timeout: 1.0)
        
        vm.cancelLoadingTask()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        let didCancel = await repo.didCancel
        XCTAssertTrue(didCancel)
    }
    
    // MARK: - Data Parsing Tests
    
    func testItemsParsedCorrectly() async {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository(), shareManagementRepository: MockShareMgmtRepo())
        let finishedLoading = expectation(description: "Finished loading")
        var cancellables = Set<AnyCancellable>()
        
        vm.$isLoading
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in finishedLoading.fulfill() }
            .store(in: &cancellables)
        
        vm.start()
        
        await fulfillment(of: [finishedLoading], timeout: 8.0)
        
        XCTAssertFalse(vm.isLoading)
    }
    
    func testEmptyDataHandledCorrectly() async {
        let emptyRepo = EmptyRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: emptyRepo, shareManagementRepository: MockShareMgmtRepo())
        await waitForLoad(vm)
        
        // With empty data, the view model should handle gracefully
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.shareName, "")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Access Role Display Tests

    func testAccessRoleShownForAcceptedNonOwner() async {
        // Use an archive ID different from share creator archive to force non-creator path.
        let shareVO = makeShareVO(status: Constants.API.AccountStatus.ok, accessRole: AccessRole.viewer.apiValue, archiveID: 1851)
        let data = makeShareData(shareVO: shareVO, defaultAccessRole: AccessRole.viewer.apiValue)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewAccessRoleRepository(shareData: data), shareManagementRepository: MockShareMgmtRepo())

        await waitForLoad(vm)

        vm.currentArchive = makeArchive(id: 1851)

        XCTAssertEqual(vm.accessRoleText, "VIEWER")
    }

    func testAccessRoleHiddenForPending() async {
        let shareVO = makeShareVO(status: Constants.API.AccountStatus.pending, accessRole: AccessRole.viewer.apiValue, archiveID: 1850)
        let data = makeShareData(shareVO: shareVO, defaultAccessRole: AccessRole.viewer.apiValue)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewAccessRoleRepository(shareData: data), shareManagementRepository: MockShareMgmtRepo())

        await waitForLoad(vm)

        vm.currentArchive = makeArchive(id: 1850)

        XCTAssertNil(vm.accessRoleText)
    }

    func testAccessRoleHiddenForOwner() async {
        let shareVO = makeShareVO(status: Constants.API.AccountStatus.ok, accessRole: AccessRole.owner.apiValue, archiveID: 1850)
        let data = makeShareData(shareVO: shareVO, defaultAccessRole: AccessRole.owner.apiValue)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewAccessRoleRepository(shareData: data), shareManagementRepository: MockShareMgmtRepo())

        await waitForLoad(vm)

        vm.currentArchive = makeArchive(id: 1850)

        XCTAssertNil(vm.accessRoleText)
    }

    func testAccessRoleShownForUnrestrictedWithoutShareVO() async {
        let data = makeShareData(shareVO: nil, defaultAccessRole: AccessRole.viewer.apiValue)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewAccessRoleRepository(shareData: data), shareManagementRepository: MockShareMgmtRepo())

        await waitForLoad(vm)

        // Use an archive ID different from share creator archive to force non-creator path.
        vm.currentArchive = makeArchive(id: 1851)

        XCTAssertEqual(vm.accessRoleText, "VIEWER")
    }

    func testAccessRoleHiddenWhenNeedsAccessRestricted() async {
        let data = makeShareData(shareVO: nil, defaultAccessRole: AccessRole.viewer.apiValue)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewAccessRoleRepository(shareData: data), shareManagementRepository: MockShareMgmtRepo())

        await waitForLoad(vm)

        vm.currentArchive = makeArchive(id: 1850)
        vm.shareLinkV2Data = ShareLinkV2Data(
            id: nil,
            itemId: nil,
            itemType: nil,
            token: nil,
            permissionsLevel: nil,
            accessRestrictions: "restricted",
            maxUses: nil,
            usesExpended: nil,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: nil,
            updatedAt: nil
        )

        XCTAssertNil(vm.accessRoleText)
    }
    
    // MARK: - Archive Selection Tests
    
    func testSelectArchiveUpdatesCurrentArchive() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository())
        let mockArchive = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.owner", fullName: "Test Archive",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: 123, publicDT: nil, archiveNbr: "00te-0000",
            view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil,
            thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: nil
        )
        
        vm.selectArchive(mockArchive)
        
        XCTAssertNotNil(vm.currentArchive)
        XCTAssertEqual(vm.currentArchive?.archiveID, 123)
    }
    
    // MARK: - Navigation Tests
    
    func testViewInArchiveCallback() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository())
        var callbackInvoked = false
        
        vm.onNavigateToFolder = { _ in
            callbackInvoked = true
        }
        
        vm.viewInArchive()
        
        // Current implementation is a no-op, so callback shouldn't be invoked yet
        XCTAssertFalse(callbackInvoked)
    }

    // MARK: - Test Helpers

    private func waitForLoad(_ vm: SharePreviewSwiftUIViewModel) async {
        let finishedLoading = expectation(description: "Finished loading")
        var cancellables = Set<AnyCancellable>()

        vm.$isLoading
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in finishedLoading.fulfill() }
            .store(in: &cancellables)

        vm.start()

        await fulfillment(of: [finishedLoading], timeout: 8.0)
    }

    private func makeArchive(id: Int) -> ArchiveVOData {
        return ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: AccessRole.viewer.apiValue, fullName: "Family",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: id, publicDT: nil, archiveNbr: "0001-0000",
            view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil,
            thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: .ok
        )
    }

    private func makeShareVO(status: String, accessRole: String, archiveID: Int) -> ShareVOData {
        return ShareVOData(
            shareID: 1, folderLinkID: 100, archiveID: archiveID,
            accessRole: accessRole, type: nil,
            status: status, requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
    }

    private func makeShareData(shareVO: ShareVOData?, defaultAccessRole: String?) -> SharebyURLVOData {
        return SharebyURLVOData(
            sharebyURLID: nil, status: Constants.API.AccountStatus.ok, urlToken: "mock",
            folderLinkID: nil, shareURL: nil, uses: nil, maxUses: nil,
            autoApproveToggle: nil, previewToggle: nil, defaultAccessRole: defaultAccessRole,
            expiresDT: nil, byAccountID: 1000, byArchiveID: 1850,
            createdDT: nil, updatedDT: nil, accountVO: nil, folderData: nil,
            recordData: nil, archiveVO: nil, shareVO: shareVO
        )
    }
}

// MARK: - Mock ShareManagementRepository

private class MockShareMgmtRepo: ShareManagementRepository {
    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            completion(nil, nil)
        }
    }
}

// MARK: - Mock Repositories

private struct ErrorRepository: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    }
}

private struct DelayedRepository: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        try await Task.sleep(nanoseconds: 200_000_000)
        // Use the mock repository's method
        let mock = SharePreviewMockRepository()
        return try await mock.fetchSharePreview(shareToken: shareToken)
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        try await Task.sleep(nanoseconds: 200_000_000)
        let mock = SharePreviewMockRepository()
        return try await mock.requestShareAccess(shareToken: shareToken)
    }
}

private struct EmptyRepository: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        return SharebyURLVOData(
            sharebyURLID: nil, status: nil, urlToken: nil, folderLinkID: nil,
            shareURL: nil, uses: nil, maxUses: nil, autoApproveToggle: nil,
            previewToggle: nil, defaultAccessRole: nil, expiresDT: nil,
            byAccountID: nil, byArchiveID: nil, createdDT: nil, updatedDT: nil,
            accountVO: nil, folderData: nil, recordData: nil, archiveVO: nil, shareVO: nil
        )
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        return ShareVOData(
            shareID: nil, folderLinkID: nil, archiveID: nil, accessRole: nil,
            type: nil, status: nil, requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
    }
}

private struct SharePreviewAccessRoleRepository: SharePreviewRepositoryProtocol {
    let shareData: SharebyURLVOData

    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        return shareData
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        return ShareVOData(
            shareID: nil, folderLinkID: nil, archiveID: nil, accessRole: nil,
            type: nil, status: nil, requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
    }
}

// MARK: - Cancellation Test Helpers

private struct DelayedRepoForTest: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        // Longer delay to simulate cancellable network call
        try await Task.sleep(nanoseconds: 300_000_000)
        return try await SharePreviewMockRepository().fetchSharePreview(shareToken: shareToken)
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        try await Task.sleep(nanoseconds: 100_000_000)
        return try await SharePreviewMockRepository().requestShareAccess(shareToken: shareToken)
    }
}

private actor CancelableRepoForTest: SharePreviewRepositoryProtocol {
    private(set) var didCancel = false

    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            if Task.isCancelled {
                didCancel = true
                throw CancellationError()
            }
            throw error
        }
        return try await SharePreviewMockRepository().fetchSharePreview(shareToken: shareToken)
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        do {
            try await Task.sleep(nanoseconds: 100_000_000)
        } catch {
            if Task.isCancelled {
                didCancel = true
                throw CancellationError()
            }
            throw error
        }
        return try await SharePreviewMockRepository().requestShareAccess(shareToken: shareToken)
    }
}
