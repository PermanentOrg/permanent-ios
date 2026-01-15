//
//  SharePreviewViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.01.2026
//

import XCTest
@testable import Permanent

@MainActor
final class SharePreviewSwiftUIViewModelTests: XCTestCase {
    
    // MARK: - Cancellation Tests
    
    func testCancelLoadingResetsIsLoading() async {
        let repo = DelayedRepo()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)

        vm.start()
        // Give the Task a moment to start
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(vm.isLoading, "isLoading should be true after start")

        vm.cancelLoadingTask()
        // Let cancellation propagate
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(vm.isLoading, "isLoading should be false after cancelLoading")
        XCTAssertNil(vm.errorMessage, "errorMessage should be nil after cancellation")
    }

    func testRepositoryCancellationPropagates() async {
        let repo = CancelableRepo()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)

        vm.start()
        try? await Task.sleep(nanoseconds: 50_000_000)
        vm.cancelLoadingTask()

        // Wait for repo to observe cancellation
        try? await Task.sleep(nanoseconds: 200_000_000)

        let didCancel = await repo.didCancel
        XCTAssertTrue(didCancel, "Repository should observe cancellation when task is cancelled")
    }
    
    // MARK: - Archive Selection Tests

    func testSelectArchive_ChangeArchiveUpdatesStateAndReloads() async {
        let repo = SharePreviewMockRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)

        let archive = ArchiveVOData.mock()

        // Override AuthenticationManager behaviour in tests
        var overrideCalled = false
        AuthenticationManager.changeArchiveOverride = { _, completion in
            overrideCalled = true
            completion(.success(true))
        }
        defer { AuthenticationManager.changeArchiveOverride = nil }

        // Act
        await MainActor.run {
            vm.selectArchive(archive)
        }

        // Wait until loading finishes
        var attempts = 0
        while vm.isLoading && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }

        // Assert
        XCTAssertTrue(overrideCalled, "changeArchive override should be called")
        XCTAssertEqual(vm.currentArchive?.archiveID, archive.archiveID)
        XCTAssertTrue(vm.needsWorkspaceReload, "needsWorkspaceReload should be true after archive change")
        XCTAssertFalse(vm.isLoading, "isLoading should be false after operation completes")
    }
    
    func testSelectArchive_WithSameArchive_DoesNotTriggerReload() async {
        let repo = SharePreviewMockRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)
        
        let archive = ArchiveVOData.mock()
        vm.currentArchive = archive
        
        var changeArchiveCalled = false
        AuthenticationManager.changeArchiveOverride = { _, completion in
            changeArchiveCalled = true
            completion(.success(true))
        }
        defer { AuthenticationManager.changeArchiveOverride = nil }
        
        // Select same archive
        vm.selectArchive(archive)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(changeArchiveCalled, "Should not call changeArchive for same archive")
        XCTAssertFalse(vm.needsWorkspaceReload, "Should not trigger reload for same archive")
    }
    
    func testSelectArchive_WithDifferentArchive_TriggersReload() async {
        let repo = SharePreviewMockRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)
        
        let archive1 = ArchiveVOData.mock()
        let archive2 = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.owner", fullName: "Different Archive",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: 9999, publicDT: nil, archiveNbr: "9999-0000",
            view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil,
            thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: nil
        )
        
        vm.currentArchive = archive1
        
        var changeArchiveCalled = false
        AuthenticationManager.changeArchiveOverride = { arch, completion in
            changeArchiveCalled = true
            XCTAssertEqual(arch.archiveID, archive2.archiveID)
            completion(.success(true))
        }
        defer { AuthenticationManager.changeArchiveOverride = nil }
        
        // Select different archive
        vm.selectArchive(archive2)
        
        var attempts = 0
        while vm.isLoading && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }
        
        XCTAssertTrue(changeArchiveCalled, "Should call changeArchive for different archive")
        XCTAssertEqual(vm.currentArchive?.archiveID, archive2.archiveID)
        XCTAssertTrue(vm.needsWorkspaceReload, "Should trigger workspace reload")
        XCTAssertEqual(vm.previousArchive?.archiveID, archive1.archiveID, "Should store previous archive")
    }
    
    func testSelectArchive_ChangeArchiveError_ShowsErrorAndRestoresPrevious() async {
        let repo = SharePreviewMockRepository()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: repo)
        
        let archive1 = ArchiveVOData.mock()
        let archive2 = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.owner", fullName: "Different Archive",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: 9999, publicDT: nil, archiveNbr: "9999-0000",
            view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil,
            thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: nil
        )
        
        vm.currentArchive = archive1
        
        AuthenticationManager.changeArchiveOverride = { _, completion in
            completion(.failure(NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to change archive"])))
        }
        defer { AuthenticationManager.changeArchiveOverride = nil }
        
        vm.selectArchive(archive2)
        
        var attempts = 0
        while vm.isLoading && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }
        
        XCTAssertNotNil(vm.errorMessage, "Should show error message")
        XCTAssertTrue(vm.errorMessage?.contains("Failed to change archive") ?? false)
        XCTAssertEqual(vm.currentArchive?.archiveID, archive1.archiveID, "Should restore previous archive on error")
    }
    
    // MARK: - Display Mode Tests
    
    //MARK: - Archive Picker State Tests
    
    func testShouldOpenArchivePicker_InitiallyFalse() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository())
        XCTAssertFalse(vm.shouldOpenArchivePicker, "shouldOpenArchivePicker should be false initially")
    }
    
    func testShowArchiveMismatchAlert_InitiallyFalse() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository())
        XCTAssertFalse(vm.showArchiveMismatchAlert, "showArchiveMismatchAlert should be false initially")
    }
    
    // MARK: - Navigation Tests
    
    func testViewInArchive_WithoutCurrentArchive_DoesNotCrash() {
        let vm = SharePreviewSwiftUIViewModel(shareToken: "token", repository: SharePreviewMockRepository())
        var navigationCalled = false
        
        vm.onNavigateToFolder = { _ in
            navigationCalled = true
        }
        
        vm.currentArchive = nil
        vm.viewInArchive()
        
        // Should not crash and should not navigate
        XCTAssertFalse(navigationCalled, "Should not navigate without current archive")
    }
}

// MARK: - Helpers

private struct DelayedRepo: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        try await Task.sleep(nanoseconds: 300_000_000)
        return try await SharePreviewMockRepository().fetchSharePreview(shareToken: shareToken)
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        try await Task.sleep(nanoseconds: 100_000_000)
        return try await SharePreviewMockRepository().requestShareAccess(shareToken: shareToken)
    }
}

private actor CancelableRepo: SharePreviewRepositoryProtocol {
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
