//
//  FilesEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class FilesEndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    private func makeRecordFile(name: String = "photo.jpg") -> FileModel {
        return FileModel(
            name: name,
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private func makeFolderFile(name: String = "My Folder") -> FileModel {
        return FileModel(
            name: name,
            recordId: 200,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.public",
            permissions: [.read]
        )
    }

    // MARK: - FolderV2Endpoint (Stela) URLs — PR1

    func testFolderV2_GetChildren_UsesCanonicalPluralPath() {
        let url = FolderV2Endpoint.getFolderChildren(folderId: "42", shareToken: "", pageSize: 100).customURL ?? ""
        XCTAssertTrue(url.contains("api/v2/folders/42/children?pageSize=100"), url)
        XCTAssertFalse(url.contains("api/v2/folder/42/children"), "Should use the canonical plural /folders route, not the deprecated singular alias")
    }

    func testFolderV2_GetById_UsesCanonicalPluralPath() {
        let url = FolderV2Endpoint.getFolderById(folderId: "42", shareToken: "").customURL ?? ""
        XCTAssertTrue(url.contains("api/v2/folders?folderIds[]=42"), url)
    }

    func testFolderV2_EmptyShareToken_ResolvesToNil() {
        // Private Files passes no share token → bearer-token auth only.
        XCTAssertNil(FolderV2Endpoint.getFolderChildren(folderId: "1", shareToken: "", pageSize: 1).shareToken)
    }

    // MARK: - RecordV2Endpoint (Stela) — detail + PATCH edit

    func testRecordV2_GetById_IsGetOnPluralRecords() {
        let endpoint = RecordV2Endpoint.getRecordById(recordId: "7", shareToken: nil)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertTrue((endpoint.customURL ?? "").contains("api/v2/records/7"), endpoint.customURL ?? "")
    }

    func testRecordV2_PatchRecord_UsesPatchAndFlatBody() {
        let endpoint = RecordV2Endpoint.patchRecord(recordId: "42", fields: ["displayName": "Renamed"])
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertTrue((endpoint.customURL ?? "").contains("api/v2/records/42"), endpoint.customURL ?? "")
        XCTAssertEqual(endpoint.headers?["Request-Version"], "2")
        XCTAssertNil(endpoint.shareToken)

        // Body is a FLAT object with ONLY the edited fields (the server rejects unknown keys).
        let body = try! JSONSerialization.jsonObject(with: endpoint.bodyData!) as! [String: Any]
        XCTAssertEqual(body["displayName"] as? String, "Renamed")
        XCTAssertEqual(body.keys.count, 1) // no recordId / archiveNbr / RequestVO envelope
    }

    func testRecordV2_PatchRecord_DescriptionBody() {
        let endpoint = RecordV2Endpoint.patchRecord(recordId: "5", fields: ["description": "notes"])
        let body = try! JSONSerialization.jsonObject(with: endpoint.bodyData!) as! [String: Any]
        XCTAssertEqual(body["description"] as? String, "notes")
        XCTAssertEqual(body.keys.count, 1)
    }

    func testRecordV2_PatchRecord_LocationBody_NeverSendsLocationId() {
        // Location edit sends the inline `location` object only — never `locationId` (server .oxor).
        let endpoint = RecordV2Endpoint.patchRecord(recordId: "5", fields: ["location": ["city": "NYC", "latitude": 40.7]])
        let body = try! JSONSerialization.jsonObject(with: endpoint.bodyData!) as! [String: Any]
        let location = body["location"] as? [String: Any]
        XCTAssertEqual(location?["city"] as? String, "NYC")
        XCTAssertNil(body["locationId"])
        XCTAssertEqual(body.keys.count, 1)
    }

    func testRecordV2_CopyRecord_PostsToCopiesWithDestinationOnly() {
        let endpoint = RecordV2Endpoint.copyRecord(recordId: "8", destinationFolderId: "42")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertTrue((endpoint.customURL ?? "").contains("api/v2/records/8/copies"), endpoint.customURL ?? "")
        XCTAssertNil(endpoint.shareToken)
        // Body carries ONLY destinationFolderId — ip + auth are injected server-side.
        let body = try! JSONSerialization.jsonObject(with: endpoint.bodyData!) as! [String: Any]
        XCTAssertEqual(body["destinationFolderId"] as? String, "42")
        XCTAssertEqual(body.keys.count, 1)
    }

    // MARK: - Paths

    func testGetRoot_Path() {
        XCTAssertEqual(FilesEndpoint.getRoot.path, "/folder/getRoot")
    }

    func testGetPublicRoot_Path() {
        XCTAssertEqual(FilesEndpoint.getPublicRoot(archiveNbr: "0001").path, "/folder/getPublicRoot")
    }

    func testNavigateMin_Path() {
        let params: NavigateMinParams = (archiveNo: "0001", folderLinkId: 1, folderName: nil)
        XCTAssertEqual(FilesEndpoint.navigateMin(params: params).path, "/folder/navigateMin")
    }

    func testGetLeanItems_Path() {
        let params: GetLeanItemsParams = (archiveNo: "0001", sortOption: .nameAscending, folderLinkIds: [1], folderLinkId: 1)
        XCTAssertEqual(FilesEndpoint.getLeanItems(params: params).path, "/folder/getLeanItems")
    }

    func testGetPresignedUrl_Path() {
        let params: GetPresignedUrlParams = (folderId: 1, folderLinkId: 1, fileMimeType: nil, filename: "f", fileSize: 100, derivedCreatedDT: nil)
        XCTAssertEqual(FilesEndpoint.getPresignedUrl(params: params).path, "/record/getPresignedUrl")
    }

    func testRegisterRecord_Path() {
        let params: RegisterRecordParams = (folderId: 1, folderLinkId: 1, filename: "f", derivedCreatedDT: nil, s3Url: "url", destinationUrl: "dest")
        XCTAssertEqual(FilesEndpoint.registerRecord(params: params).path, "/record/registerRecord")
    }

    func testNewFolder_Path() {
        let params: NewFolderParams = (filename: "New Folder", folderLinkId: 1)
        XCTAssertEqual(FilesEndpoint.newFolder(params: params).path, "/folder/post")
    }

    func testDelete_AllRecords_Path() {
        let files = [makeRecordFile()]
        XCTAssertEqual(FilesEndpoint.delete(params: files).path, "/record/delete")
    }

    func testDelete_AllFolders_Path() {
        let folders = [makeFolderFile()]
        XCTAssertEqual(FilesEndpoint.delete(params: folders).path, "/folder/delete")
    }

    func testGetRecord_Path() {
        let params: GetRecordParams = (folderLinkId: 1, parentFolderLinkId: 2)
        XCTAssertEqual(FilesEndpoint.getRecord(itemInfo: params).path, "/record/get")
    }

    func testGetFolder_Path() {
        let params: GetRecordParams = (folderLinkId: 1, parentFolderLinkId: 2)
        XCTAssertEqual(FilesEndpoint.getFolder(itemInfo: params).path, "/folder/get")
    }

    func testUpdate_Path() {
        let params: UpdateRecordParams = (name: "n", description: nil, date: nil, location: nil, recordId: 1, folderLinkId: 1, archiveNbr: "0001")
        XCTAssertEqual(FilesEndpoint.update(params: params).path, "/record/update")
    }

    func testMultipleUpdate_Path() {
        let params: UpdateMultipleRecordsParams = (files: [makeRecordFile()], description: nil, location: nil)
        XCTAssertEqual(FilesEndpoint.multipleUpdate(params: params).path, "/record/update")
    }

    func testMultipleFilesUpdate_Path() {
        XCTAssertEqual(FilesEndpoint.multipleFilesUpdate(files: [makeRecordFile()]).path, "/record/update")
    }

    func testRenameFolder_Path() {
        let params: UpdateRecordParams = (name: "n", description: nil, date: nil, location: nil, recordId: 1, folderLinkId: 1, archiveNbr: "0001")
        XCTAssertEqual(FilesEndpoint.renameFolder(params: params).path, "/folder/update")
    }

    func testUpdateRootColumns_Path() {
        let params: UpdateRootColumnsParams = (thumbArchiveNbr: "0001", folderId: 1, folderArchiveNbr: "0002", folderLinkId: 1)
        XCTAssertEqual(FilesEndpoint.updateRootColumns(params: params).path, "/folder/updateRootColumns")
    }

    func testUnshareRecord_Path() {
        XCTAssertEqual(FilesEndpoint.unshareRecord(archiveId: 1, folderLinkId: 1).path, "/share/delete")
    }

    // MARK: - Relocate Paths

    func testRelocate_CopyRecords_Path() {
        let items: ItemPair = (files: [makeRecordFile()], destination: makeFolderFile())
        let params: RelocateParams = (items: items, action: .copy)
        XCTAssertEqual(FilesEndpoint.relocate(params: params).path, "/record/copy")
    }

    func testRelocate_MoveRecords_Path() {
        let items: ItemPair = (files: [makeRecordFile()], destination: makeFolderFile())
        let params: RelocateParams = (items: items, action: .move)
        XCTAssertEqual(FilesEndpoint.relocate(params: params).path, "/record/move")
    }

    func testRelocate_CopyFolders_Path() {
        let items: ItemPair = (files: [makeFolderFile()], destination: makeFolderFile())
        let params: RelocateParams = (items: items, action: .copy)
        XCTAssertEqual(FilesEndpoint.relocate(params: params).path, "/folder/copy")
    }

    func testRelocate_MoveFolders_Path() {
        let items: ItemPair = (files: [makeFolderFile()], destination: makeFolderFile())
        let params: RelocateParams = (items: items, action: .move)
        XCTAssertEqual(FilesEndpoint.relocate(params: params).path, "/folder/move")
    }

    // MARK: - Method

    func testMethod_MostEndpoints_Post() {
        let endpoints: [FilesEndpoint] = [
            .getRoot,
            .newFolder(params: (filename: "f", folderLinkId: 1)),
            .update(params: (name: nil, description: nil, date: nil, location: nil, recordId: 1, folderLinkId: 1, archiveNbr: "0001"))
        ]
        for endpoint in endpoints {
            XCTAssertEqual(endpoint.method, .post)
        }
    }

    func testMethod_Download_Get() {
        let endpoint = FilesEndpoint.download(url: URL(string: "https://example.com/file")!, filename: "f", progressHandler: nil)
        XCTAssertEqual(endpoint.method, .get)
    }

    // MARK: - Request/Response Types

    func testRequestType_Default_Data() {
        XCTAssertEqual(FilesEndpoint.getRoot.requestType, .data)
    }

    func testRequestType_Download_Download() {
        let endpoint = FilesEndpoint.download(url: URL(string: "https://example.com")!, filename: "f", progressHandler: nil)
        XCTAssertEqual(endpoint.requestType, .download)
    }

    func testResponseType_Default_JSON() {
        XCTAssertEqual(FilesEndpoint.getRoot.responseType, .json)
    }

    func testResponseType_Download_File() {
        let endpoint = FilesEndpoint.download(url: URL(string: "https://example.com")!, filename: "f", progressHandler: nil)
        XCTAssertEqual(endpoint.responseType, .file)
    }

    // MARK: - customURL

    func testCustomURL_Download_ReturnsURLString() {
        let url = URL(string: "https://cdn.example.com/file.pdf")!
        let endpoint = FilesEndpoint.download(url: url, filename: "file.pdf", progressHandler: nil)
        XCTAssertEqual(endpoint.customURL, "https://cdn.example.com/file.pdf")
    }

    func testCustomURL_NonDownload_ReturnsNil() {
        XCTAssertNil(FilesEndpoint.getRoot.customURL)
    }

    // MARK: - progressHandler

    func testProgressHandler_Download_ReturnsHandler() {
        var called = false
        let handler: ProgressHandler = { _ in called = true }
        let endpoint = FilesEndpoint.download(url: URL(string: "https://example.com")!, filename: "f", progressHandler: handler)
        endpoint.progressHandler?(0.5)
        XCTAssertTrue(called)
    }

    func testProgressHandler_NonDownload_ReturnsNil() {
        XCTAssertNil(FilesEndpoint.getRoot.progressHandler)
    }

    // MARK: - FilesEndpointPayloads: navigateMin

    func testNavigateMinPayload_WithFolderLinkId() {
        let params: NavigateMinParams = (archiveNo: "0001-abc", folderLinkId: 42, folderName: nil)
        let payload = dict(FilesEndpointPayloads.navigateMinPayload(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let folderVO = data?.first?["FolderVO"] as? [String: Any]
        XCTAssertEqual(folderVO?["archiveNbr"] as? String, "0001-abc")
        XCTAssertEqual(folderVO?["folder_linkId"] as? String, "42")
    }

    func testNavigateMinPayload_WithoutFolderLinkId() {
        let params: NavigateMinParams = (archiveNo: "0001-abc", folderLinkId: -1, folderName: nil)
        let payload = dict(FilesEndpointPayloads.navigateMinPayload(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let folderVO = data?.first?["FolderVO"] as? [String: Any]
        XCTAssertEqual(folderVO?["archiveNbr"] as? String, "0001-abc")
        XCTAssertNil(folderVO?["folder_linkId"])
    }

    // MARK: - FilesEndpointPayloads: newFolder

    func testNewFolderPayload_ContainsDisplayName() {
        let params: NewFolderParams = (filename: "Photos", folderLinkId: 55)
        let payload = dict(FilesEndpointPayloads.newFolderPayload(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let folderVO = data?.first?["FolderVO"] as? [String: Any]
        XCTAssertEqual(folderVO?["displayName"] as? String, "Photos")
        XCTAssertEqual(folderVO?["parentFolder_linkId"] as? Int, 55)
    }

    // MARK: - FilesEndpointPayloads: getPresignedUrl

    func testGetPresignedUrlPayload_ContainsFileInfo() {
        let params: GetPresignedUrlParams = (folderId: 10, folderLinkId: 20, fileMimeType: "image/jpeg", filename: "photo.jpg", fileSize: 5000, derivedCreatedDT: nil)
        let payload = dict(FilesEndpointPayloads.getPresignedUrlPayload(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let recordVO = data?.first?["RecordVO"] as? [String: Any]
        XCTAssertEqual(recordVO?["parentFolderId"] as? Int, 10)
        XCTAssertEqual(recordVO?["displayName"] as? String, "photo.jpg")
        XCTAssertEqual(recordVO?["size"] as? Int, 5000)
    }

    func testGetPresignedUrlPayload_NilMimeType_UsesOctetStream() {
        let params: GetPresignedUrlParams = (folderId: 1, folderLinkId: 1, fileMimeType: nil, filename: "f", fileSize: 100, derivedCreatedDT: nil)
        let payload = dict(FilesEndpointPayloads.getPresignedUrlPayload(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let simpleVO = data?.first?["SimpleVO"] as? [String: Any]
        XCTAssertEqual(simpleVO?["value"] as? String, "application/octet-stream")
    }

    // MARK: - FilesEndpointPayloads: registerRecord

    func testRegisterRecordPayload_ContainsKeys() {
        let params: RegisterRecordParams = (folderId: 5, folderLinkId: 10, filename: "test.pdf", derivedCreatedDT: "2026-01-01T00:00:00", s3Url: "https://s3.example.com", destinationUrl: "https://dest.example.com")
        let payload = dict(FilesEndpointPayloads.registerRecord(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [String: Any]
        let recordVO = data?["RecordVO"] as? [String: Any]
        XCTAssertEqual(recordVO?["parentFolderId"] as? Int, 5)
        XCTAssertEqual(recordVO?["displayName"] as? String, "test.pdf")
        XCTAssertEqual(recordVO?["derivedCreatedDT"] as? String, "2026-01-01T00:00:00")
    }

    func testRegisterRecordPayload_NilCreatedDT_ExcludesKey() {
        let params: RegisterRecordParams = (folderId: 1, folderLinkId: 1, filename: "f", derivedCreatedDT: nil, s3Url: "s3", destinationUrl: "dest")
        let payload = dict(FilesEndpointPayloads.registerRecord(for: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [String: Any]
        let recordVO = data?["RecordVO"] as? [String: Any]
        XCTAssertNil(recordVO?["derivedCreatedDT"])
    }

    // MARK: - FilesEndpointPayloads: unshareRecord

    func testUnshareRecordPayload_ContainsShareVO() {
        let payload = dict(FilesEndpointPayloads.unshareRecord(archiveId: 42, folderLinkId: 99))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareVO = data?.first?["ShareVO"] as? [String: Any]
        XCTAssertEqual(shareVO?["folder_linkId"] as? Int, 99)
        XCTAssertEqual(shareVO?["archiveId"] as? Int, 42)
    }

    // MARK: - FilesEndpointPayloads: updateRootColumns

    func testUpdateRootColumnsPayload_ContainsFolderVO() {
        let params: UpdateRootColumnsParams = (thumbArchiveNbr: "thumb-001", folderId: 5, folderArchiveNbr: "arch-001", folderLinkId: 10)
        let payload = dict(FilesEndpointPayloads.updateRootColumns(params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let folderVO = data?.first?["FolderVO"] as? [String: Any]
        XCTAssertEqual(folderVO?["thumbArchiveNbr"] as? String, "thumb-001")
        XCTAssertEqual(folderVO?["folderId"] as? Int, 5)
        XCTAssertEqual(folderVO?["archiveNbr"] as? String, "arch-001")
        XCTAssertEqual(folderVO?["folder_linkId"] as? Int, 10)
    }

    // MARK: - FilesEndpointPayloads: updateRecordRequest

    func testUpdateRecordRequest_WithName() {
        let params: UpdateRecordParams = (name: "NewName", description: nil, date: nil, location: nil, recordId: 1, folderLinkId: 2, archiveNbr: "0001")
        let payload = dict(FilesEndpointPayloads.updateRecordRequest(params: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let recordVO = data?.first?["RecordVO"] as? [String: Any]
        XCTAssertEqual(recordVO?["displayName"] as? String, "NewName")
        XCTAssertEqual(recordVO?["recordId"] as? Int, 1)
    }

    func testUpdateRecordRequest_WithDescription() {
        let params: UpdateRecordParams = (name: nil, description: "A description", date: nil, location: nil, recordId: 1, folderLinkId: 1, archiveNbr: "0001")
        let payload = dict(FilesEndpointPayloads.updateRecordRequest(params: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let recordVO = data?.first?["RecordVO"] as? [String: Any]
        XCTAssertEqual(recordVO?["description"] as? String, "A description")
        XCTAssertNil(recordVO?["displayName"])
    }

    func testUpdateRecordRequest_WithDate() {
        let date = Date(timeIntervalSince1970: 0)
        let params: UpdateRecordParams = (name: nil, description: nil, date: date, location: nil, recordId: 1, folderLinkId: 1, archiveNbr: "0001")
        let payload = dict(FilesEndpointPayloads.updateRecordRequest(params: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let recordVO = data?.first?["RecordVO"] as? [String: Any]
        XCTAssertNotNil(recordVO?["displayDT"])
    }

    // MARK: - FilesEndpointPayloads: renameFolderRequest

    func testRenameFolderRequest_ContainsFolderVO() {
        let params: UpdateRecordParams = (name: "Renamed", description: nil, date: nil, location: nil, recordId: 5, folderLinkId: 10, archiveNbr: "0001-xyz")
        let payload = dict(FilesEndpointPayloads.renameFolderRequest(params: params))
        let requestVO = payload?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let folderVO = data?.first?["FolderVO"] as? [String: Any]
        XCTAssertEqual(folderVO?["displayName"] as? String, "Renamed")
        XCTAssertEqual(folderVO?["folderId"] as? Int, 5)
        XCTAssertEqual(folderVO?["archiveNbr"] as? String, "0001-xyz")
    }
}
