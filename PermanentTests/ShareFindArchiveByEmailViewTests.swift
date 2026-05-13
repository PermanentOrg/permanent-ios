//
//  ShareFindArchiveByEmailViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 08.05.2026.
//

import XCTest
import SwiftUI
import UIKit
import Combine
@testable import Permanent

@MainActor
final class ShareFindArchiveByEmailViewTests: XCTestCase {

    // MARK: - Rendering Tests

    func testRendersInIdleState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.findArchiveByEmailViewModel.visibleOutcomeState, 0)
    }

    func testRendersWhileSearching() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "search@example.com"
        vm.findArchiveByEmailViewModel.performSearch()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.findArchiveByEmailViewModel.isSearching)
    }

    func testRendersAfterSearchCompletes() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "nonexistent-test-xyz@permanent.org"
        vm.findArchiveByEmailViewModel.performSearch()

        let searchDone = XCTestExpectation(description: "Search completes")
        var cancellables = Set<AnyCancellable>()

        vm.findArchiveByEmailViewModel.$isSearching
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in searchDone.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [searchDone], timeout: 10.0)

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(vm.findArchiveByEmailViewModel.isSearching)
    }

    func testRendersAfterClearSearch() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "test@example.com"
        vm.findArchiveByEmailViewModel.performSearch()
        vm.findArchiveByEmailViewModel.clearSearch()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.findArchiveByEmailViewModel.searchText, "")
        XCTAssertEqual(vm.findArchiveByEmailViewModel.visibleOutcomeState, 0)
    }

    func testRendersWithNonEmptySearchText() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "partial"

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.findArchiveByEmailViewModel.searchText, "partial")
    }

    func testRendersAfterReset() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "test@example.com"
        vm.findArchiveByEmailViewModel.performSearch()
        vm.findArchiveByEmailViewModel.reset()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.findArchiveByEmailViewModel.visibleOutcomeState, 0)
    }

    func testRendersWithInvalidEmailSearch() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "not-valid"
        let result = vm.findArchiveByEmailViewModel.performSearch()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(result)
    }

    func testMultipleRendersWithDifferentStates() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(host.view)

        vm.findArchiveByEmailViewModel.searchText = "user@test.com"
        vm.findArchiveByEmailViewModel.performSearch()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(host.view)

        vm.findArchiveByEmailViewModel.clearSearch()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(host.view)
    }

    func testRenderDoesNotCrashWithEmptySearchText() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = ""

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRendersWithSearchTextChangeTrigger() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.findArchiveByEmailViewModel.searchText = "a"
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.findArchiveByEmailViewModel.searchText = "ab"
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.findArchiveByEmailViewModel.searchText = "abc@test.com"
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: FindArchiveViewTestRepository()
        )
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func waitForInitialLoad(of viewModel: ShareItemViewModel) async {
        let deadline = Date().addingTimeInterval(2.0)
        while Date() < deadline {
            if !viewModel.isLoading {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}

private final class FindArchiveViewTestRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }

    override func getShareLinkV2(shareLinkId: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}
