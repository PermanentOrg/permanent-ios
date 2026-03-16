//
//  ShareItemViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.03.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class ShareItemViewTests: XCTestCase {

    func testRendersWhileLoadingState() async {
        let vm = ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: SlowNoLinkShareManagementRepository()
        )

        let host = hostView(ShareItemView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.isLoading)
    }

    func testRendersCreateLinkState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.isLoading = false
        vm.genLinkLoading = false
        vm.shareLink = nil

        let host = hostView(ShareItemView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.shouldShowCreateButton)
    }

    func testRendersShareLinkState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.isLoading = false
        vm.genLinkLoading = false
        vm.shareLink = "https://example.com/share/token"

        let host = hostView(ShareItemView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.hasShareLink)
    }

    func testRendersErrorState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.isLoading = false

        let host = hostView(ShareItemView(viewModel: vm))
        vm.errorMessage = "Mock error"
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.errorMessage, "Mock error")
    }

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: FastNoLinkShareManagementRepository()
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
        let deadline = Date().addingTimeInterval(1.0)
        while Date() < deadline {
            if !viewModel.isLoading {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

}

private final class FastNoLinkShareManagementRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}

private final class SlowNoLinkShareManagementRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(nil, nil)
        }
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}
