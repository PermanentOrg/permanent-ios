//
//  SharePreviewViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.03.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class SharePreviewViewTests: XCTestCase {

    func testOnAppearStartsLoadingShareData() async {
        let repo = ObservingRepo()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)
        let host = UIHostingController(rootView: SharePreviewView(viewModel: vm))
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = host
        window.makeKeyAndVisible()

        let fetchCount = await waitUntilValue(timeout: 1.5, valueProvider: { await repo.fetchCount() }) { $0 == 1 }
        let token = await repo.lastToken()

        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(token, "test-token")
    }

    func testOnDisappearCancelsLoadingTask() async {
        let repo = DelayedRepo(delayNanos: 1_000_000_000)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)
        let host = UIHostingController(rootView: SharePreviewView(viewModel: vm))
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = host
        window.makeKeyAndVisible()

        let startedLoading = await waitUntil(timeout: 1.0) {
            vm.isLoading
        }
        XCTAssertTrue(startedLoading)

        window.rootViewController = UIViewController()

        let stoppedLoading = await waitUntil(timeout: 1.5) {
            !vm.isLoading
        }
        XCTAssertTrue(stoppedLoading, "View disappearing should cancel loading task")
    }

    func testLoadingStateTurnsTrueWhileViewLoads() async {
        let repo = DelayedRepo(delayNanos: 1_000_000_000)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)
        let host = UIHostingController(rootView: SharePreviewView(viewModel: vm))
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = host
        window.makeKeyAndVisible()

        let enteredLoading = await waitUntil(timeout: 1.0) {
            vm.isLoading
        }

        XCTAssertTrue(enteredLoading, "View should drive view model into loading state on appear")
    }

    func testPickerStateTogglesForViewBinding() async {
        let repo = DelayedRepo(delayNanos: 1_000_000_000)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)
        _ = UIHostingController(rootView: SharePreviewView(viewModel: vm))

        XCTAssertFalse(vm.shouldOpenArchivePicker)
        vm.shouldOpenArchivePicker = true
        XCTAssertTrue(vm.shouldOpenArchivePicker)

        vm.shouldOpenArchivePicker = false
        XCTAssertFalse(vm.shouldOpenArchivePicker)
    }

    func testArchiveMismatchAlertPresentsWhenStateIsTrue() async {
        let repo = DelayedRepo(delayNanos: 1_000_000_000)
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)
        let host = UIHostingController(rootView: SharePreviewView(viewModel: vm))
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = host
        window.makeKeyAndVisible()

        vm.showArchiveMismatchAlert = true

        let didPresentAlert = await waitUntil(timeout: 1.0) {
            host.presentedViewController is UIAlertController
        }
        XCTAssertTrue(didPresentAlert, "Archive mismatch alert should be presented when state toggles true")
    }

    private func waitUntil(timeout: TimeInterval, condition: @escaping () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return condition()
    }

    private func waitUntilValue<T>(
        timeout: TimeInterval,
        valueProvider: @escaping () async -> T,
        predicate: (T) -> Bool
    ) async -> T {
        let deadline = Date().addingTimeInterval(timeout)
        var latest = await valueProvider()
        while Date() < deadline {
            if predicate(latest) {
                return latest
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
            latest = await valueProvider()
        }
        return latest
    }

}

private actor ObservingRepo: SharePreviewRepositoryProtocol {
    private var internalFetchCount = 0
    private var internalLastToken: String?

    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        internalFetchCount += 1
        internalLastToken = shareToken
        return makeShareData()
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        makeShareVO(status: "status.share.ok")
    }

    func fetchCount() -> Int { internalFetchCount }
    func lastToken() -> String? { internalLastToken }

    private func makeShareData() -> SharebyURLVOData {
        SharebyURLVOData(
            sharebyURLID: nil,
            status: Constants.API.AccountStatus.ok,
            urlToken: "mock",
            folderLinkID: nil,
            shareURL: nil,
            uses: nil,
            maxUses: nil,
            autoApproveToggle: nil,
            previewToggle: 1,
            defaultAccessRole: AccessRole.viewer.apiValue,
            expiresDT: nil,
            byAccountID: 1000,
            byArchiveID: 1850,
            createdDT: nil,
            updatedDT: nil,
            accountVO: nil,
            folderData: nil,
            recordData: nil,
            archiveVO: nil,
            shareVO: makeShareVO(status: "status.share.ok")
        )
    }

    private func makeShareVO(status: String) -> ShareVOData {
        ShareVOData(
            shareID: 1,
            folderLinkID: 100,
            archiveID: 1850,
            accessRole: AccessRole.viewer.apiValue,
            type: nil,
            status: status,
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }
}

private actor DelayedRepo: SharePreviewRepositoryProtocol {
    private let delayNanos: UInt64

    init(delayNanos: UInt64) {
        self.delayNanos = delayNanos
    }

    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        try? await Task.sleep(nanoseconds: delayNanos)
        return SharebyURLVOData(
            sharebyURLID: nil,
            status: Constants.API.AccountStatus.ok,
            urlToken: "mock",
            folderLinkID: nil,
            shareURL: nil,
            uses: nil,
            maxUses: nil,
            autoApproveToggle: nil,
            previewToggle: 1,
            defaultAccessRole: AccessRole.viewer.apiValue,
            expiresDT: nil,
            byAccountID: 1000,
            byArchiveID: 1850,
            createdDT: nil,
            updatedDT: nil,
            accountVO: nil,
            folderData: nil,
            recordData: nil,
            archiveVO: nil,
            shareVO: nil
        )
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        ShareVOData(
            shareID: 1,
            folderLinkID: 100,
            archiveID: 1850,
            accessRole: AccessRole.viewer.apiValue,
            type: nil,
            status: "status.share.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }
}
