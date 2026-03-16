//
//  ArchiveAccessManagementViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class ArchiveAccessManagementViewTests: XCTestCase {

    func testOnAppearInitializesSelectedRoleFromArchive() async {
        let vm = makeViewModel()
        vm.selectedArchiveForEdit = makeShareVO(accessRole: AccessRole.editor.apiValue)
        vm.selectedRoleForArchive = nil

        let (host, _) = hostView(ArchiveAccessManagementView(viewModel: vm))
        _ = host.view

        let initialized = await waitUntil(timeout: 1.0) {
            vm.selectedRoleForArchive == .editor
        }

        XCTAssertTrue(initialized)
    }

    func testOnAppearDoesNotOverrideAlreadySelectedRole() async {
        let vm = makeViewModel()
        vm.selectedArchiveForEdit = makeShareVO(accessRole: AccessRole.viewer.apiValue)
        vm.selectedRoleForArchive = .manager

        let (host, _) = hostView(ArchiveAccessManagementView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.selectedRoleForArchive, .manager)
    }

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: PassiveShareManagementRepository()
        )
    }

    private func makeShareVO(accessRole: String) -> ShareVOData {
        let archive = ArchiveVOData.mock()
        return ShareVOData(
            shareID: 1,
            folderLinkID: 100,
            archiveID: archive.archiveID,
            accessRole: accessRole,
            type: nil,
            status: "status.share.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: archive,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }

    private func hostView<Content: View>(_ view: Content) -> (UIHostingController<Content>, UIWindow) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
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
}

private final class PassiveShareManagementRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}
