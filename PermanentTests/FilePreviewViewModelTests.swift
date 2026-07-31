//
//  FilePreviewViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class FilePreviewViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(permissions: [Permission] = [.read, .edit, .share]) -> FilePreviewViewModel {
        var file = FileModel.mockFile()
        file.permissions = permissions
        return FilePreviewViewModel(file: file)
    }

    /// Builds a RecordVO through the real V2 adapter, so these tests exercise the same
    /// `fileVOS` shape the app receives from Stela rather than a hand-built stand-in.
    private func makeRecordWithFiles(_ filesJSON: String) -> RecordVO {
        let json = """
        { "data": {
            "recordId": "89793", "displayName": "file_example_ODS_100", "archiveId": "3227",
            "archiveNumber": "01on-0006", "uploadFileName": "file_example_ODS_100.ods",
            "size": 68446, "type": "type.record.spreadsheet", "folderLinkId": "137946",
            "files": [ \(filesJSON) ]
        } }
        """
        let v2 = try! RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data!
        return JSONHelper.decoding(from: v2.toRecordVOPayload(), with: RecordVO.decoder)!
    }

    private let odsOriginalJSON = """
    { "fileId": "1318542", "size": 68446, "format": "file.format.original",
      "type": "type.file.spreadsheet.ods",
      "fileUrl": "https://cdn/originals/1318542",
      "downloadUrl": "https://cdn/originals/1318542?response-content-disposition=attachment" }
    """

    private let accessCopyPDFJSON = """
    { "fileId": "1318544", "size": 29249, "format": "file.format.archivematica.access",
      "type": "type.file.pdf.pdf",
      "fileUrl": "https://cdn/access_copies/1318542.pdf",
      "downloadUrl": "https://cdn/access_copies/1318542.pdf?response-content-disposition=x.pdf" }
    """

    // MARK: - pdfAccessCopyURL
    // A spreadsheet's original has no inline renderer: WebKit converts the navigation into a
    // download, the provisional load fails (WebKitErrorDomain 102) and the preview showed
    // nothing. The Archivematica PDF rendition is what actually gets displayed.

    func testPDFAccessCopyURL_ReturnsArchivematicaPDF_NotTheOriginal() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(odsOriginalJSON), \(accessCopyPDFJSON)")

        XCTAssertEqual(vm.pdfAccessCopyURL()?.absoluteString,
                       "https://cdn/access_copies/1318542.pdf",
                       "must render the access copy, and via fileUrl — downloadUrl's content-disposition asks for a save")
    }

    func testPDFAccessCopyURL_NilWhenRecordHasOnlyTheOriginal() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles(odsOriginalJSON)

        XCTAssertNil(vm.pdfAccessCopyURL(),
                     "with no rendition the caller must fall back to loadMisc, not pass nil to loadPDF")
    }

    func testPDFAccessCopyURL_IgnoresAnOriginalPDF() {
        // A record that IS a pdf takes the .pdf branch already; only a generated ACCESS copy
        // may stand in for an unrenderable original.
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("""
        { "fileId": "1", "size": 10, "format": "file.format.original", "type": "type.file.pdf.pdf",
          "fileUrl": "https://cdn/originals/1.pdf" }
        """)

        XCTAssertNil(vm.pdfAccessCopyURL())
    }

    func testFileVO_StaysOnTheOriginal_WhenAnAccessCopyExists() {
        // The preview swap must not leak into download/filename — the user downloads the .ods
        // they uploaded, not its PDF rendition.
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(odsOriginalJSON), \(accessCopyPDFJSON)")

        XCTAssertEqual(vm.fileVO()?.type, "type.file.spreadsheet.ods")
        XCTAssertEqual(vm.fileName(), "file_example_ODS_100.ods")
    }

    // MARK: - isAwaitingPDFRendition
    // Archivematica generates the access copy asynchronously. A document opened moments
    // after upload has only its original, which is "not ready yet" rather than broken —
    // reporting it as a load failure is what made a freshly uploaded .xlsx look unopenable.

    func testIsAwaitingPDFRendition_TrueWhenOnlyTheOriginalIsPresent() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles(odsOriginalJSON)

        XCTAssertTrue(vm.isAwaitingPDFRendition)
    }

    func testIsAwaitingPDFRendition_FalseOnceTheAccessCopyExists() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(odsOriginalJSON), \(accessCopyPDFJSON)")

        XCTAssertFalse(vm.isAwaitingPDFRendition,
                       "the rendition arrived — waiting longer would spin for nothing")
    }

    func testIsAwaitingPDFRendition_FalseWhenANonOriginalRenditionExists() {
        // A converted rendition that simply isn't a PDF means conversion already ran;
        // there is nothing further to wait for.
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("""
        \(odsOriginalJSON),
        { "fileId": "9", "size": 1, "format": "file.format.converted",
          "type": "type.file.video.mp4", "fileUrl": "https://cdn/c.mp4" }
        """)

        XCTAssertFalse(vm.isAwaitingPDFRendition)
    }

    func testIsAwaitingPDFRendition_FalseWithNoRecordOrNoFiles() {
        let noRecord = makeVM()
        XCTAssertFalse(noRecord.isAwaitingPDFRendition, "nothing fetched yet is not a pending rendition")

        let noFiles = makeVM()
        noFiles.recordVO = RecordVO(recordVO: nil)
        XCTAssertFalse(noFiles.isAwaitingPDFRendition)
    }

    // MARK: - Initialization

    func testInit_SetsNameFromFile() {
        let file = FileModel.mockFile()
        let vm = FilePreviewViewModel(file: file)
        XCTAssertEqual(vm.name, file.name)
    }

    func testInit_RecordVOIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.recordVO)
    }

    func testInit_PublicURLIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.publicURL)
    }

    func testInit_DownloaderIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.downloader)
    }

    func testInit_DelegateIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.delegate)
    }

    func testInit_TagsRepositoryCreated() {
        let vm = makeVM()
        XCTAssertNotNil(vm.tagsRepository)
    }

    // MARK: - isEditable

    func testIsEditable_WithEditPermission_ReturnsTrue() {
        let vm = makeVM(permissions: [.read, .edit])
        XCTAssertTrue(vm.isEditable)
    }

    func testIsEditable_WithoutEditPermission_ReturnsFalse() {
        let vm = makeVM(permissions: [.read, .share])
        XCTAssertFalse(vm.isEditable)
    }

    func testIsEditable_EmptyPermissions_ReturnsFalse() {
        let vm = makeVM(permissions: [])
        XCTAssertFalse(vm.isEditable)
    }

    func testIsEditable_AllPermissions_ReturnsTrue() {
        let vm = makeVM(permissions: [.read, .edit, .share, .create, .delete, .move])
        XCTAssertTrue(vm.isEditable)
    }

    // MARK: - fileVO()

    func testFileVO_NilRecordVO_ReturnsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.fileVO())
    }

    // MARK: - fileThumbnailURL()

    func testFileThumbnailURL_NilRecordVO_ReturnsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.fileThumbnailURL())
    }

    // MARK: - fileName()

    func testFileName_NilRecordVO_ReturnsEmptyString() {
        let vm = makeVM()
        XCTAssertEqual(vm.fileName(), "")
    }

    // MARK: - getAddressString

    func testGetAddressString_AllValues() {
        let vm = makeVM()
        let result = vm.getAddressString(["123", "Main St", "NYC", "US"])
        XCTAssertEqual(result, "123, Main St, NYC, US")
    }

    func testGetAddressString_WithNils() {
        let vm = makeVM()
        let result = vm.getAddressString([nil, "Main St", nil, "US"])
        XCTAssertEqual(result, "Main St, US")
    }

    func testGetAddressString_AllNil_Editable() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([nil, nil, nil, nil])
        XCTAssertEqual(result, "Tap to set".localized())
    }

    func testGetAddressString_AllNil_NotEditable() {
        let vm = makeVM(permissions: [.read])
        let result = vm.getAddressString([nil, nil, nil, nil])
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_AllNil_NotInMetadataScreen() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([nil, nil, nil, nil], false)
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_SingleValue() {
        let vm = makeVM()
        let result = vm.getAddressString(["New York"])
        XCTAssertEqual(result, "New York")
    }

    func testGetAddressString_EmptyArray() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([])
        XCTAssertEqual(result, "Tap to set".localized())
    }

    func testGetAddressString_EmptyArray_NotEditable() {
        let vm = makeVM(permissions: [.read])
        let result = vm.getAddressString([])
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_MixedNilAndValues() {
        let vm = makeVM()
        let result = vm.getAddressString([nil, "Street", nil, nil, "Country"])
        XCTAssertEqual(result, "Street, Country")
    }

    // MARK: - cancelDownload

    func testCancelDownload_SetsDownloaderToNil() {
        let vm = makeVM()
        vm.cancelDownload()
        XCTAssertNil(vm.downloader)
    }

    // MARK: - File property

    func testFile_IsStoredFromInit() {
        let file = FileModel.mockFile()
        let vm = FilePreviewViewModel(file: file)
        XCTAssertEqual(vm.file.name, file.name)
        XCTAssertEqual(vm.file.recordId, file.recordId)
        XCTAssertEqual(vm.file.folderLinkId, file.folderLinkId)
        XCTAssertEqual(vm.file.archiveNo, file.archiveNo)
    }

    // MARK: - Name mutability

    func testName_CanBeChanged() {
        let vm = makeVM()
        vm.name = "NewName.pdf"
        XCTAssertEqual(vm.name, "NewName.pdf")
    }

    // MARK: - PublicURL

    func testPublicURL_CanBeSet() {
        let vm = makeVM()
        vm.publicURL = URL(string: "https://example.com/file")
        XCTAssertNotNil(vm.publicURL)
        XCTAssertEqual(vm.publicURL?.absoluteString, "https://example.com/file")
    }
}

// MARK: - Image preview state machine (VSP-1768)

private final class MockReachability: ReachabilityProviding {
    var isConnected: Bool

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}

extension FilePreviewViewModelTests {

    private func makeImageVM(isConnected: Bool = true) -> (FilePreviewViewModel, MockReachability) {
        let reachability = MockReachability(isConnected: isConnected)
        let vm = FilePreviewViewModel(file: FileModel.mockFile(), reachability: reachability)
        return (vm, reachability)
    }

    func testStartImageLoad_WithThumbnail_EntersLoadingThumbnail() {
        let (vm, _) = makeImageVM()

        XCTAssertTrue(vm.startImageLoad(hasThumbnail: true))
        XCTAssertEqual(vm.imagePreviewState, .loadingThumbnail)
    }

    func testStartImageLoad_NoThumbnail_EntersLoadingFullResWithoutThumbnail() {
        let (vm, _) = makeImageVM()

        XCTAssertTrue(vm.startImageLoad(hasThumbnail: false))
        XCTAssertEqual(vm.imagePreviewState, .loadingFullRes(hasThumbnail: false))
    }

    func testStartImageLoad_Offline_EntersOfflineState_AndBlocksLoading() {
        let (vm, _) = makeImageVM(isConnected: false)

        XCTAssertFalse(vm.startImageLoad(hasThumbnail: true))
        XCTAssertEqual(vm.imagePreviewState, .offline(hasThumbnail: true))
    }

    func testThumbnailDidLoad_TransitionsToLoadingFullRes() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)

        vm.thumbnailDidLoad()

        XCTAssertEqual(vm.imagePreviewState, .loadingFullRes(hasThumbnail: true))
    }

    func testFullResDidLoad_TransitionsToLoaded() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailDidLoad()

        vm.fullResDidLoad()

        XCTAssertEqual(vm.imagePreviewState, .loaded)
    }

    func testImageLoadDidFail_Online_EntersFailedState_PreservingHasThumbnail() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailDidLoad()

        vm.imageLoadDidFail(error: nil)

        XCTAssertEqual(vm.imagePreviewState, .failed(hasThumbnail: true))
    }

    func testImageLoadDidFail_Online_NoThumbnail_KeepsHasThumbnailFalse() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: false)

        vm.imageLoadDidFail(error: nil)

        XCTAssertEqual(vm.imagePreviewState, .failed(hasThumbnail: false))
    }

    func testImageLoadDidFail_Offline_EntersOfflineState() {
        let (vm, reachability) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailDidLoad()
        reachability.isConnected = false

        vm.imageLoadDidFail(error: nil)

        XCTAssertEqual(vm.imagePreviewState, .offline(hasThumbnail: true))
    }

    func testImageLoadDidFail_AfterLoaded_IsIgnored() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.fullResDidLoad()

        vm.imageLoadDidFail(error: nil)

        XCTAssertEqual(vm.imagePreviewState, .loaded)
    }

    func testRetryRequested_Online_EntersLoadingFullRes_ReturnsTrue() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailDidLoad()
        vm.imageLoadDidFail(error: nil)

        XCTAssertTrue(vm.retryRequested())
        XCTAssertEqual(vm.imagePreviewState, .loadingFullRes(hasThumbnail: true))
    }

    func testRetryRequested_StillOffline_StaysOffline_ReturnsFalse() {
        let (vm, _) = makeImageVM(isConnected: false)
        vm.startImageLoad(hasThumbnail: true)

        XCTAssertFalse(vm.retryRequested())
        XCTAssertEqual(vm.imagePreviewState, .offline(hasThumbnail: true))
    }

    func testConnectivityRestored_FromOffline_ResumesLoading() {
        let (vm, reachability) = makeImageVM(isConnected: false)
        vm.startImageLoad(hasThumbnail: true)
        reachability.isConnected = true

        XCTAssertTrue(vm.connectivityRestored())
        XCTAssertEqual(vm.imagePreviewState, .loadingFullRes(hasThumbnail: true))
    }

    func testConnectivityRestored_WhenNotOffline_DoesNothing() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.fullResDidLoad()

        XCTAssertFalse(vm.connectivityRestored())
        XCTAssertEqual(vm.imagePreviewState, .loaded)
    }

    func testStateChangeClosure_FiresOnlyOnDistinctStates() {
        let (vm, _) = makeImageVM()
        var observedStates: [ImagePreviewState] = []
        vm.onImagePreviewStateChanged = { observedStates.append($0) }

        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailDidLoad()
        vm.thumbnailDidLoad()
        vm.fullResDidLoad()

        XCTAssertEqual(observedStates, [.loadingThumbnail, .loadingFullRes(hasThumbnail: true), .loaded])
    }

    // MARK: - Thumbnail failure while full-res is pending (VSP-1777 follow-up)

    /// A transient THUMBNAIL failure must not paint the failure card while the
    /// record fetch → full-res pipeline can still deliver: it downgrades to the
    /// no-thumbnail loading state (S5) instead.
    func testThumbnailLoadDidFail_WhileLoadingThumbnail_KeepsLoadingState() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)

        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))

        XCTAssertEqual(vm.imagePreviewState, .loadingFullRes(hasThumbnail: false))
    }

    /// The reported bug: thumbnail fails, full-res lands ~1s later. The user must see
    /// loading → loaded, with the failed card NEVER flashing in between.
    func testThumbnailLoadDidFail_ThenFullResLoads_NeverShowsFailedState() {
        let (vm, _) = makeImageVM()
        var observedStates: [ImagePreviewState] = []
        vm.onImagePreviewStateChanged = { observedStates.append($0) }

        vm.startImageLoad(hasThumbnail: true)
        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))
        vm.fullResDidLoad()

        XCTAssertEqual(observedStates, [.loadingThumbnail, .loadingFullRes(hasThumbnail: false), .loaded])
    }

    /// When the full-res load genuinely fails after the thumbnail already failed,
    /// the terminal failed state still surfaces (with no thumbnail under the card).
    func testThumbnailLoadDidFail_ThenFullResFails_EndsFailedWithoutThumbnail() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)

        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))
        vm.imageLoadDidFail(error: NSError(domain: "test", code: -2))

        XCTAssertEqual(vm.imagePreviewState, .failed(hasThumbnail: false))
    }

    func testThumbnailLoadDidFail_AfterLoaded_IsIgnored() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.fullResDidLoad()

        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))

        XCTAssertEqual(vm.imagePreviewState, .loaded)
    }

    /// A record-fetch failure that already painted the failure card wins over a
    /// late-arriving thumbnail failure — the card must keep its hasThumbnail flag.
    func testThumbnailLoadDidFail_WhenAlreadyFailed_IsIgnored() {
        let (vm, _) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        vm.imageLoadDidFail(error: nil) // record fetch failed first → .failed(hasThumbnail: true)

        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))

        XCTAssertEqual(vm.imagePreviewState, .failed(hasThumbnail: true))
    }

    func testThumbnailLoadDidFail_Offline_EntersOfflineState() {
        let (vm, reachability) = makeImageVM()
        vm.startImageLoad(hasThumbnail: true)
        reachability.isConnected = false

        vm.thumbnailLoadDidFail(error: NSError(domain: "test", code: -1))

        XCTAssertEqual(vm.imagePreviewState, .offline(hasThumbnail: false))
    }

    /// Regression test for the former infinite retry loop: repeated record-fetch
    /// failures must stop after maxRecordFetchAttempts and report nil to the caller.
    func testOnRecordCallback_RepeatedErrors_StopsAfterCapAndCallsHandlerWithNil() {
        final class GetRecordSpyViewModel: FilePreviewViewModel {
            var getRecordCallCount = 0
            override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
                getRecordCallCount += 1
            }
        }

        let vm = GetRecordSpyViewModel(file: FileModel.mockFile(), reachability: MockReachability(isConnected: true))
        let error = NSError(domain: "test", code: -1)
        var handlerCalled = false
        var handlerRecord: RecordVO? = RecordVO(recordVO: nil)
        let handler: (RecordVO?) -> Void = { record in
            handlerCalled = true
            handlerRecord = record
        }

        // Failures below the cap retry by re-calling getRecord, never the handler.
        vm.onRecordCallback(file: FileModel.mockFile(), record: nil, error: error, then: handler)
        XCTAssertEqual(vm.getRecordCallCount, 1)
        XCTAssertFalse(handlerCalled)

        vm.onRecordCallback(file: FileModel.mockFile(), record: nil, error: error, then: handler)
        XCTAssertEqual(vm.getRecordCallCount, 2)
        XCTAssertFalse(handlerCalled)

        // The attempt that reaches the cap stops retrying and surfaces nil.
        vm.onRecordCallback(file: FileModel.mockFile(), record: nil, error: error, then: handler)
        XCTAssertEqual(vm.getRecordCallCount, 2)
        XCTAssertTrue(handlerCalled)
        XCTAssertNil(handlerRecord)
    }

    func testOnRecordCallback_Offline_FailsImmediately() {
        let (vm, _) = makeImageVM(isConnected: false)
        var handlerCalled = false
        var handlerRecord: RecordVO? = RecordVO(recordVO: nil)

        vm.onRecordCallback(file: FileModel.mockFile(), record: nil, error: NSError(domain: "test", code: -1)) { record in
            handlerCalled = true
            handlerRecord = record
        }

        XCTAssertTrue(handlerCalled)
        XCTAssertNil(handlerRecord)
    }

    // MARK: - VSP-1787 sibling: V2 public-root resolution for the publish destination
    // resolvePublicRootFolderIdV2 = archives → match archiveNbr → rootFolderId → the
    // public-root child of that root. Any failure returns nil so publish falls back to V1
    // getPublicRoot.

    private func decodeArchivesV2(_ json: String) -> [ArchiveV2Data] {
        guard let data = json.data(using: .utf8) else { return [] }
        return (try? ArchivesV2Response.decoder.decode(ArchivesV2Response.self, from: data))?.items ?? []
    }

    private func decodeChildrenV2(_ json: String) -> [FolderChildV2Data] {
        guard let data = json.data(using: .utf8) else { return [] }
        return (try? FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: data))?.items ?? []
    }

    /// Archive-root children mirroring the live staging shape, with a parameterized public-root.
    private func archiveRootChildrenJSON(publicFolderId: String = "700", publicType: String = "public-root") -> String {
        return """
        { "items": [
          { "folderId": "598", "displayName": "Apps", "type": "app-root", "status": "ok", "folderLinkId": "701", "archiveNumber": "0001-0002" },
          { "folderId": "599", "displayName": "My Files", "type": "private-root", "status": "ok", "folderLinkId": "702", "archiveNumber": "0001-0003" },
          { "folderId": "\(publicFolderId)", "displayName": "Public", "type": "\(publicType)", "status": "ok", "folderLinkId": "703", "archiveNumber": "0001-0004" }
        ] }
        """
    }

    /// FilePreviewViewModel with the session archive pinned (archiveNbr "1001" = ArchiveVOData.mock()).
    private func withPublishVM(_ body: (FilePreviewViewModel) -> Void) {
        let previous = AuthenticationManager.shared.session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock() // archiveNbr "1001"
        AuthenticationManager.shared.session = session
        defer { AuthenticationManager.shared.session = previous }
        body(FilePreviewViewModel(file: FileModel.mockFile()))
    }

    func testResolvePublicRootV2_HappyPath_ReturnsPublicRootFolderId() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            var requestedFolderId: String?
            vm.rootChildrenFetchV2Request = { folderId, completion in
                requestedFolderId = folderId
                completion(.success(self.decodeChildrenV2(self.archiveRootChildrenJSON())))
            }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertEqual(requestedFolderId, "500", "children fetched for the matched archive's rootFolderId")
            XCTAssertEqual(result, "700", "resolves the public-root child's folderId")
        }
    }

    func testResolvePublicRootV2_MultiArchive_SelectsByArchiveNbr() {
        withPublishVM { vm in
            // Decoy first (different rootFolderId); the session archive "1001" is second.
            vm.archivesFetchV2Request = {
                $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"2002","rootFolderId":"999"},{"archiveNbr":"1001","rootFolderId":"500"}]}"#)))
            }
            var requestedFolderId: String?
            vm.rootChildrenFetchV2Request = { folderId, completion in
                requestedFolderId = folderId
                completion(.success(self.decodeChildrenV2(self.archiveRootChildrenJSON())))
            }
            var result: String?
            vm.resolvePublicRootFolderIdV2 { result = $0 }
            XCTAssertEqual(requestedFolderId, "500", "selection is by archiveNbr, not list position")
            XCTAssertEqual(result, "700")
        }
    }

    func testResolvePublicRootV2_NoSelectedArchive_ReturnsNilWithoutFetch() {
        let previous = AuthenticationManager.shared.session
        AuthenticationManager.shared.session = nil
        defer { AuthenticationManager.shared.session = previous }
        let vm = FilePreviewViewModel(file: FileModel.mockFile())
        var archivesFetched = false
        vm.archivesFetchV2Request = { _ in archivesFetched = true }
        var result: String?; var done = false
        vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
        XCTAssertTrue(done)
        XCTAssertNil(result)
        XCTAssertFalse(archivesFetched, "no current archive → never hits the network")
    }

    func testResolvePublicRootV2_ArchiveNotListed_ReturnsNilWithoutChildrenFetch() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"9999","rootFolderId":"500"}]}"#))) }
            var childrenFetched = false
            vm.rootChildrenFetchV2Request = { _, _ in childrenFetched = true }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertNil(result)
            XCTAssertFalse(childrenFetched, "no rootFolderId resolved → no children call")
        }
    }

    func testResolvePublicRootV2_ArchivesFetchFails_ReturnsNil() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.failure(APIError.serverError)) }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertNil(result)
        }
    }

    func testResolvePublicRootV2_RootChildrenFails_ReturnsNil() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in completion(.failure(APIError.serverError)) }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertNil(result)
        }
    }

    func testResolvePublicRootV2_NoPublicRootChild_ReturnsNil() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            // "Public" present by name but typed "public" (not "public-root"); no public-root child.
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildrenV2(self.archiveRootChildrenJSON(publicType: "public"))))
            }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertNil(result, "no public-root type child → nil (publish falls back to V1)")
        }
    }

    func testResolvePublicRootV2_BadFolderId_ReturnsNil() {
        withPublishVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchivesV2(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildrenV2(self.archiveRootChildrenJSON(publicFolderId: "0"))))
            }
            var result: String?; var done = false
            vm.resolvePublicRootFolderIdV2 { result = $0; done = true }
            XCTAssertTrue(done)
            XCTAssertNil(result, "a non-positive folderId is a contract break → nil")
        }
    }
}

// MARK: - ImagePreviewViewController fitted-geometry invariant (VSP-1777: "small then zoom" glitch)
//
// The full-res "small then grows" glitch came from the image being made visible (blur fading)
// BEFORE newImageLoaded() ran sizeToFit()/setZoomScale(). These tests pin the invariant the fix
// relies on: newImageLoaded() always fits the CURRENT image to the CURRENT scrollView frame, so
// applying it atomically at swap time (before the blur lifts) yields the correct size immediately.

final class ImagePreviewViewControllerGeometryTests: XCTestCase {

    /// A loaded controller with a known, fixed scrollView frame (no window / layout passes,
    /// so `setZoomScale()` reads exactly the frame we set — matching how newImageLoaded()
    /// computes geometry at full-res-arrival time).
    private func makeVC(width: CGFloat = 400, height: CGFloat = 800) -> ImagePreviewViewController {
        let vc = ImagePreviewViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        vc.loadViewIfNeeded()
        vc.scrollView.frame = vc.view.bounds
        return vc
    }

    /// A solid image whose point `size` equals the given dimensions (what `sizeToFit()` reads).
    /// Forced to scale = 1 so a large "full-res" size does not allocate a screen-scale (~@3x)
    /// bitmap — only the point size matters to the geometry under test, never the pixels.
    private func image(_ width: CGFloat, _ height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    /// The on-screen width of the image = its (point) bounds width scaled by the scroll zoom.
    private func displayedWidth(_ vc: ImagePreviewViewController) -> CGFloat {
        vc.imageView.bounds.width * vc.scrollView.zoomScale
    }

    func testNewImageLoaded_LandscapeImage_FitsToScreenWidth() {
        let vc = makeVC(width: 400, height: 800)
        vc.imageView.image = image(4309, 2527) // the reported bear photo aspect
        vc.newImageLoaded()

        XCTAssertEqual(displayedWidth(vc), 400, accuracy: 0.5)
        // Zoom must rest exactly at the fitted minimum — no residual zoom-in.
        XCTAssertEqual(vc.scrollView.zoomScale, vc.scrollView.minimumZoomScale, accuracy: 0.0001)
        // No-regression guard: for images larger than the screen (minScale < 1) the maximum stays
        // at the native 1.0, so pinch-to-zoom up to 100% is unchanged by the sub-screen fix.
        XCTAssertEqual(vc.scrollView.maximumZoomScale, 1.0, accuracy: 0.0001)
    }

    /// Regression test for the sub-screen shrink surfaced in review. An original SMALLER than the
    /// screen needs a fit scale > 1 (here 256px on a 400pt screen ≈ 1.57). The scroll view's
    /// default maximumZoomScale of 1.0 used to clamp it, so the image rendered at its native 256pt
    /// — narrower than the full-width blur placeholder — and appeared to shrink when the blur
    /// lifted. Raising maximumZoomScale to the fit scale makes it fill the width (400pt), matching
    /// the blur, so there is no shrink. (This also removes the thumbnail/full-res size gap that
    /// the crossfade used to flash, on top of the atomic-swap ordering fix.)
    func testNewImageLoaded_SubScreenImage_FillsToScreenWidth_NotClampedToNative() {
        let vc = makeVC(width: 400, height: 800)

        vc.imageView.image = image(256, 150) // sub-screen original (also the 256px thumbnail case)
        vc.newImageLoaded()

        XCTAssertEqual(displayedWidth(vc), 400, accuracy: 0.5,
                       "a sub-screen image fills the width instead of clamping to its 256pt native size")
        XCTAssertEqual(vc.scrollView.maximumZoomScale, vc.scrollView.minimumZoomScale, accuracy: 0.0001,
                       "maximumZoomScale is raised to the fit scale so zoomScale is not clamped below fit")
        XCTAssertEqual(vc.scrollView.zoomScale, vc.scrollView.minimumZoomScale, accuracy: 0.0001)
    }

    /// newImageLoaded() must fit the CURRENT image to the CURRENT scrollView frame. Geometry can
    /// first be computed against a smaller frame (the preview view not yet laid out to device
    /// size during pager preload); when the full-res lands after the view reaches its real size,
    /// newImageLoaded() recomputes to the correct width — which is why the fix applies it at
    /// full-res-arrival, before the blur lifts.
    func testNewImageLoaded_RecomputesForCurrentFrame_AfterFrameGrows() {
        let vc = makeVC(width: 200, height: 400) // stale, smaller frame

        vc.imageView.image = image(4309, 2527)
        vc.newImageLoaded()
        XCTAssertEqual(displayedWidth(vc), 200, accuracy: 0.5) // fitted to the stale frame

        // Full-res arrives after the view reached its real device width.
        vc.scrollView.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        vc.newImageLoaded()
        XCTAssertEqual(displayedWidth(vc), 400, accuracy: 0.5) // corrected to the real frame
    }

    /// A portrait image (taller than the screen aspect) is height-constrained and must fit to
    /// height, never overflow width.
    func testNewImageLoaded_PortraitImage_FitsToHeight() {
        let vc = makeVC(width: 400, height: 800)
        vc.imageView.image = image(1000, 4000) // very tall

        vc.newImageLoaded()

        let displayedHeight = vc.imageView.bounds.height * vc.scrollView.zoomScale
        XCTAssertEqual(displayedHeight, 800, accuracy: 0.5)
        XCTAssertLessThanOrEqual(displayedWidth(vc), 400 + 0.5)
    }
}
