//
//  ShareArchivesV2SourceTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.09.2026.
//

import Foundation
import Testing
@testable import Permanent

/// Pins that the shared-archives list is served by the Stela item read, and that it hands off to the
/// legacy read only when Stela's answer would be incomplete.
/// Serialized: the view model's init issues a request, so a late completion lands in another test.
@MainActor
@Suite(.serialized)
struct ShareArchivesV2SourceTests {

    // MARK: - Which path served the list

    @Test("A manager's response serves the list without the legacy read")
    func managerResponseServesTheList() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "manager", shares: [
            Self.share(id: 9, archiveId: 3, name: "Family", status: "status.generic.ok")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(ShareItemViewModel.lastSharedArchivesSource == "v2")
        #expect(vm.sharedArchives.count == 1)
        #expect(vm.sharedArchives.first?.shareID == 9)
        #expect(vm.sharedArchives.first?.archiveVO?.fullName == "Family")
        #expect(vm.isLoadingArchives == false)
    }

    @Test("A curator's response hands off, because the server strips requested rows below manager")
    func curatorResponseHandsOffToLegacy() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "curator", shares: [
            Self.share(id: 9, archiveId: 3, name: "Family", status: "status.generic.ok")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(ShareItemViewModel.lastSharedArchivesSource == "v1")
    }

    @Test("An absent shares key hands off, because absent means no answer")
    func absentSharesKeyHandsOffToLegacy() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner", shares: nil)

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(ShareItemViewModel.lastSharedArchivesSource == "v1")
    }

    @Test("An empty shares array is an answer, and empties the section")
    func emptySharesArrayIsAnAnswer() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner", shares: [])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(ShareItemViewModel.lastSharedArchivesSource == "v2")
        #expect(vm.sharedArchives.isEmpty)
        #expect(vm.shouldShowArchivesSection == false)
    }

    @Test("A failed read hands off to the legacy read")
    func failedReadHandsOffToLegacy() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = { _, _, completion in completion(.error(nil, nil)) }

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(ShareItemViewModel.lastSharedArchivesSource == "v1")
    }

    // MARK: - One read, not two

    @Test("One open issues a single item read, because one response carries both share lists")
    func oneOpenIssuesASingleRead() async throws {
        let vm = await makeViewModel()
        let counter = CallCounter()
        let stub = Self.folderStub(callerRole: "owner", shares: [], pendingShares: [
            Self.pendingShare(id: 77, email: "ada@example.com", name: "Ada")
        ])
        vm.folderFetchV2Request = { folderId, token, completion in
            counter.bump()
            stub(folderId, token, completion)
        }

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(counter.count == 1)
        #expect(vm.sharedArchives.count == 1)
        #expect(vm.sharedArchives.first?.accountVO?.primaryEmail == "ada@example.com")
    }

    // MARK: - Row content

    @Test("Requested rows sort ahead of approved ones")
    func requestedRowsSortFirst() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner", shares: [
            Self.share(id: 1, archiveId: 3, name: "Approved", status: "status.generic.ok"),
            Self.share(id: 2, archiveId: 4, name: "Requested", status: "status.generic.pending")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(vm.sharedArchives.first?.shareID == 2)
        #expect(vm.pendingShares.count == 1)
    }

    @Test("Every row carries a folder link id, which unshare needs")
    func everyRowCarriesAFolderLinkId() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner",
                                                  folderLinkId: "4242",
                                                  shares: [
            Self.share(id: 9, archiveId: 3, name: "Family", status: "status.generic.ok")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(vm.sharedArchives.first?.folderLinkID == 4242)
        #expect(vm.sharedArchives.first?.archiveID == 3)
    }

    @Test("The owner row is dropped, so only the archives you shared with remain")
    func ownerRowIsDropped() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner", shares: [
            Self.share(id: 1, archiveId: 3, name: "Theirs", status: "status.generic.ok"),
            Self.share(id: 2, archiveId: 4, name: "Owner", status: "status.generic.ok",
                       accessRole: "access.role.owner")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(vm.sharedArchives.count == 1)
        #expect(vm.sharedArchives.first?.shareID == 1)
    }

    @Test("The archive thumbnail survives the mapping")
    func archiveThumbnailSurvivesMapping() async throws {
        let vm = await makeViewModel()
        vm.folderFetchV2Request = Self.folderStub(callerRole: "owner", shares: [
            Self.share(id: 9, archiveId: 3, name: "Family", status: "status.generic.ok",
                       thumbUrl200: "https://example.com/200.jpg")
        ])

        vm.fetchSharedArchives()
        try await waitUntil { ShareItemViewModel.lastSharedArchivesSource != "none" }

        #expect(vm.sharedArchives.first?.archiveVO?.preferredThumbnailURL == "https://example.com/200.jpg")
    }

    // MARK: - Helpers

    private final class CallCounter: @unchecked Sendable {
        private(set) var count = 0
        func bump() { count += 1 }
    }

    private static func share(id: Int,
                              archiveId: Int,
                              name: String,
                              status: String,
                              accessRole: String = "access.role.viewer",
                              thumbUrl200: String? = nil) -> String {
        let thumb = thumbUrl200.map { ", \"thumbUrl200\": \"\($0)\"" } ?? ""
        return """
        {"id": "\(id)", "accessRole": "\(accessRole)", "status": "\(status)",
         "archive": {"id": "\(archiveId)", "name": "\(name)"\(thumb)}}
        """
    }

    private static func pendingShare(id: Int, email: String, name: String) -> String {
        """
        {"id": "\(id)", "email": "\(email)", "name": "\(name)", "accessRole": "access.role.viewer"}
        """
    }

    private static func folderStub(callerRole: String,
                                   folderLinkId: String = "1",
                                   shares: [String]?,
                                   pendingShares: [String] = []) -> (String, String?, @escaping (OperationResult) -> Void) -> Void {
        let sharesJSON = shares.map { ", \"shares\": [\($0.joined(separator: ","))]" } ?? ""
        let pendingJSON = pendingShares.isEmpty ? "" : ", \"pendingShares\": [\(pendingShares.joined(separator: ","))]"
        let body = """
        {"items": [{"id": "55", "folderId": "55", "folderLinkId": "\(folderLinkId)",
                    "accessRole": "\(callerRole)"\(sharesJSON)\(pendingJSON)}]}
        """
        // The decoder re-serializes, so hand it a JSON object rather than raw bytes.
        let object = try? JSONSerialization.jsonObject(with: Data(body.utf8), options: [])
        return { _, _, completion in
            completion(.json(object, nil))
        }
    }

    /// A folder carrying a Stela folder id, which `FileModel.mockFolder()` does not: the legacy
    /// initialisers hardcode it to -1, so a mock built from one never reaches the Stela read.
    private static func folderWithStelaId() -> FileModel {
        let json = """
        {"folderId": "55", "displayName": "Test Folder", "folderLinkId": "1",
         "type": "type.folder.private", "archiveId": "1", "archiveNumber": "0001-0000"}
        """
        let object = try? JSONSerialization.jsonObject(with: Data(json.utf8), options: [])
        guard let child: FolderChildV2Data = JSONHelper.decoding(from: object,
                                                                with: FolderV2Response.decoder) else {
            return FileModel.mockFolder()
        }
        return FileModel(model: child, permissions: [.read, .edit, .share], accessRole: .owner)
    }

    private func makeViewModel() async -> ShareItemViewModel {
        ShareItemViewModel.lastSharedArchivesSource = "none"

        let vm = ShareItemViewModel(
            fileModel: Self.folderWithStelaId(),
            shareManagementRepository: ShareManagementRepository()
        )

        let deadline = Date().addingTimeInterval(2.0)
        while vm.isLoading && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        vm.sharedArchives = []
        vm.errorMessage = nil
        ShareItemViewModel.lastSharedArchivesSource = "none"
        return vm
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(3.0)
        while !condition() && Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(condition(), "condition did not become true within the timeout")
    }
}
