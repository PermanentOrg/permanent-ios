//
//  FilePreviewViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import AVFoundation
import AVKit
import PDFKit
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
    private func makeRecordWithFiles(_ filesJSON: String, recordType: String = "type.record.spreadsheet") -> RecordVO {
        let json = """
        { "data": {
            "recordId": "89793", "displayName": "file_example_ODS_100", "archiveId": "3227",
            "archiveNumber": "01on-0006", "uploadFileName": "file_example_ODS_100.ods",
            "size": 68446, "type": "\(recordType)", "folderLinkId": "137946",
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
    // A spreadsheet's original has no inline renderer: WebKit turns the navigation into a download
    // and the preview shows nothing. The PDF rendition is what actually gets displayed.

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

    func testFileVO_PicksTheOriginal_WhenTheServerListsTheAccessCopyFirst() {
        // Stela lists a record's files in no fixed order, so the original is found by its format.
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(accessCopyPDFJSON), \(odsOriginalJSON)")

        XCTAssertEqual(vm.fileVO()?.format, "file.format.original")
        XCTAssertEqual(vm.fileName(), "file_example_ODS_100.ods")
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

    // MARK: - playbackFiles()
    // Playback follows the web: the access copy, then the original, then the conversion, which may
    // carry no playable audio track. The server's order of the files never matters.

    func testPlaybackFiles_AccessCopyThenOriginalThenConversion_WhateverTheServerOrder() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoConvertedJSON), \(videoOriginalJSON), \(videoAccessCopyJSON)",
                                          recordType: FileType.video.rawValue)

        XCTAssertEqual(vm.playbackFiles().map(\.format),
                       ["file.format.archivematica.access", "file.format.original", "file.format.converted"])
        XCTAssertEqual(vm.fileVO()?.format, "file.format.original", "file names keep the user's own file")
    }

    func testPlaybackFiles_OriginalBeforeTheConversion_WhenThereIsNoAccessCopy() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoConvertedJSON), \(videoOriginalJSON)", recordType: FileType.video.rawValue)

        XCTAssertEqual(vm.playbackFiles().map(\.format), ["file.format.original", "file.format.converted"])
    }

    func testPlaybackFiles_LeavesOutAFileWithoutALink() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoAccessCopyWithoutLinksJSON), \(videoOriginalJSON)",
                                          recordType: FileType.video.rawValue)

        XCTAssertEqual(vm.playbackFiles().map(\.format), ["file.format.original"])
    }

    func testPlaybackFiles_EmptyForADocument() {
        // Only audio and video walk the list: a document must never silently swap to a rendition.
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(odsOriginalJSON), \(videoConvertedJSON)")

        XCTAssertTrue(vm.playbackFiles().isEmpty)
    }

    func testPlaybackURL_PrefersThePlainLink_ThenTheDownloadLink() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoAccessCopyJSON), \(videoOriginalWithDownloadLinkOnlyJSON)",
                                          recordType: FileType.video.rawValue)
        let files = vm.playbackFiles()

        XCTAssertEqual(files.first?.playbackURL?.absoluteString, "https://cdn/access_copies/2000.mp4")
        XCTAssertEqual(files.last?.playbackURL?.absoluteString,
                       "https://cdn/originals/2000?response-content-disposition=attachment")
    }

    // MARK: - assetOptions(for:contentType:)

    func testAssetOptions_NameTheTypeOnlyForALinkWithoutAnExtension() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("The player takes a named type from iOS 17.") }
        let original = try XCTUnwrap(URL(string: "https://cdn/originals/2000/2000"))
        let accessCopy = try XCTUnwrap(URL(string: "https://cdn/access_copies/2000.mp4"))

        let named = FilePreviewViewModel.assetOptions(for: original, contentType: "video/mp4")
        XCTAssertEqual(named[AVURLAssetOverrideMIMETypeKey] as? String, "video/mp4")
        XCTAssertTrue(FilePreviewViewModel.assetOptions(for: accessCopy, contentType: "video/mp4").isEmpty)
        XCTAssertTrue(FilePreviewViewModel.assetOptions(for: original, contentType: "application/octet-stream").isEmpty)
        XCTAssertTrue(FilePreviewViewModel.assetOptions(for: original, contentType: nil).isEmpty)
        XCTAssertTrue(FilePreviewViewModel.assetOptions(for: URL(fileURLWithPath: "/saved/clip"), contentType: "video/mp4").isEmpty,
                      "a saved copy on the phone needs no hint")
    }

    func testTypeHintRetry_OnlyAfterCannotOpen_OnALinkWithoutAnExtension() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("The player takes a named type from iOS 17.") }
        let original = try XCTUnwrap(URL(string: "https://cdn/originals/2000/2000"))
        let accessCopy = try XCTUnwrap(URL(string: "https://cdn/access_copies/2000.mp4"))
        let cannotOpen = NSError(domain: AVFoundationErrorDomain, code: AVError.Code.fileFormatNotRecognized.rawValue)
        let otherFailure = NSError(domain: AVFoundationErrorDomain, code: AVError.Code.unknown.rawValue)

        let retry = FilePreviewViewModel.typeHintRetryOptions(after: cannotOpen, url: original, contentType: "video/mp4")
        XCTAssertEqual(retry?[AVURLAssetOverrideMIMETypeKey] as? String, "video/mp4")
        XCTAssertNil(FilePreviewViewModel.typeHintRetryOptions(after: cannotOpen, url: accessCopy, contentType: "video/mp4"))
        XCTAssertNil(FilePreviewViewModel.typeHintRetryOptions(after: otherFailure, url: original, contentType: "video/mp4"))
        XCTAssertNil(FilePreviewViewModel.typeHintRetryOptions(after: nil, url: original, contentType: "video/mp4"))
    }

    // MARK: - Play list

    func testPlayList_HandsOutEachFileOnce_InPlayOrder() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoConvertedJSON), \(videoOriginalJSON), \(videoAccessCopyJSON)",
                                          recordType: FileType.video.rawValue)
        vm.startPlayback()

        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.archivematica.access")
        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.original")
        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.converted")
        XCTAssertNil(vm.nextFile(), "each file is tried once, so failures cannot loop")
    }

    func testPlayList_StartsOverOnANewLoad() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoOriginalJSON), \(videoAccessCopyJSON)", recordType: FileType.video.rawValue)
        vm.startPlayback()
        _ = vm.nextFile()

        vm.startPlayback()

        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.archivematica.access")
    }

    func testPlayList_HandsOutNothing_WhenTheOnlyFileHasNoLink() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles(unknownFormatWithoutLinksJSON, recordType: FileType.video.rawValue)
        vm.startPlayback()

        XCTAssertNil(vm.nextFile())
    }

    func testPlaybackFiles_AudioPlaysTheAccessCopyFirst() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(audioOriginalJSON), \(audioAccessCopyJSON)", recordType: FileType.audio.rawValue)

        XCTAssertEqual(vm.playbackFiles().map(\.format), ["file.format.archivematica.access", "file.format.original"])
    }

    func testPlaybackFiles_FallBackToTheFirstFile_WhenNoFormatIsKnown() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles(unknownFormatJSON, recordType: FileType.video.rawValue)

        XCTAssertEqual(vm.playbackFiles().map(\.format), ["file.format.1920x1080"])
    }

    func testFileVO_FallsBackToTheFirstFile_WhenNoneIsMarkedOriginal() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(accessCopyPDFJSON), \(videoConvertedJSON)")

        XCTAssertEqual(vm.fileVO()?.format, "file.format.archivematica.access")
    }

    // MARK: - previewFiles()
    // Photos and PDFs open the user's own upload first, as they always did. The access copy and the
    // conversion only stand in when it cannot open.

    func testPreviewFiles_OriginalThenAccessCopyThenConversion_WhateverTheServerOrder() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(imageConvertedJSON), \(imageAccessCopyJSON), \(imageOriginalJSON)",
                                          recordType: FileType.image.rawValue)

        XCTAssertEqual(vm.previewFiles().map(\.format),
                       ["file.format.original", "file.format.archivematica.access", "file.format.converted"])
    }

    func testPreviewFiles_OnlyForPhotosAndPDFs() {
        let vm = makeVideoVM()
        vm.recordVO = makeRecordWithFiles("\(videoOriginalJSON), \(videoAccessCopyJSON)", recordType: FileType.video.rawValue)
        XCTAssertTrue(vm.previewFiles().isEmpty, "audio and video play in the web's order")

        vm.recordVO = makeRecordWithFiles("\(odsOriginalJSON), \(accessCopyPDFJSON)")
        XCTAssertTrue(vm.previewFiles().isEmpty, "a document keeps its own PDF rendition preview")
    }

    func testPreviewURL_PrefersTheDownloadLink_ThenThePlainLink() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(imageOriginalJSON), \(imageAccessCopyWithPlainLinkOnlyJSON)",
                                          recordType: FileType.image.rawValue)
        let files = vm.previewFiles()

        XCTAssertEqual(files.first?.previewURL?.absoluteString,
                       "https://cdn/originals/4000?response-content-disposition=attachment")
        XCTAssertEqual(files.last?.previewURL?.absoluteString, "https://cdn/access_copies/4000.jpg")
    }

    func testPreviewList_HandsOutEachFileOnce_InOpenOrder() {
        let vm = makeVM()
        vm.recordVO = makeRecordWithFiles("\(imageConvertedJSON), \(imageAccessCopyJSON), \(imageOriginalJSON)",
                                          recordType: FileType.image.rawValue)
        vm.startPreview()

        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.original")
        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.archivematica.access")
        XCTAssertEqual(vm.nextFile()?.file.format, "file.format.converted")
        XCTAssertNil(vm.nextFile(), "each file is tried once, so failures cannot loop")
    }

    // MARK: - Preview screen

    func testLoadAV_OverALivePlayer_ReplacesIt() throws {
        // A reload over a live player must stop watching the old item first, or KVO raises on the new one.
        let vc = try XCTUnwrap(UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController)
        vc.file = FileModel(name: "clip.mov", recordId: 89793, folderLinkId: 137946, archiveNbr: "01on-0006",
                            type: FileType.video.rawValue, permissions: [.read])
        vc.loadViewIfNeeded()

        vc.loadAV(withURL: URL(fileURLWithPath: "/missing-first.mp4"), contentType: "")
        vc.loadAV(withURL: URL(fileURLWithPath: "/missing-second.mp4"), contentType: "")

        XCTAssertEqual(vc.children.filter { $0 is AVPlayerViewController }.count, 1)
    }

    func testRemoveVideoPlayer_HidesTheAudioPlayButton() throws {
        // A failed audio file must not leave a play button with no player behind it.
        let vc = try XCTUnwrap(UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController)
        vc.file = FileModel(name: "voice.wav", recordId: 89794, folderLinkId: 137947, archiveNbr: "01on-0007",
                            type: FileType.audio.rawValue, permissions: [.read])
        vc.loadViewIfNeeded()
        vc.loadAudio(withURL: URL(fileURLWithPath: "/missing-audio.wav"), contentType: "")
        vc.overlayView.isHidden = false

        vc.removeVideoPlayer()

        XCTAssertTrue(vc.overlayView.isHidden)
    }

    func testPDF_ThatCannotOpen_HandsOverToTheNextCopy() throws {
        let pdf = try writeTemporaryFile(UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200)).pdfData { $0.beginPage() },
                                         extension: "pdf")
        let vc = try makePreviewScreen(type: .pdf, files: """
            { "fileId": "5000", "format": "file.format.original", "type": "type.file.pdf.pdf",
              "downloadUrl": "\(missingFileURL(extension: "pdf"))" },
            { "fileId": "5001", "format": "file.format.archivematica.access", "type": "type.file.pdf.pdf",
              "downloadUrl": "\(pdf.absoluteString)" }
            """)

        vc.loadRecord()

        let opened = expectation(for: NSPredicate { _, _ in
            vc.view.subviews.contains { ($0 as? PDFView)?.document != nil }
        }, evaluatedWith: nil)
        wait(for: [opened], timeout: 10)
    }

    func testPhoto_ThatCannotOpen_HandsOverToTheNextCopy() throws {
        let png = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).pngData { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let photo = try writeTemporaryFile(png, extension: "png")
        let vc = try makePreviewScreen(type: .image, files: """
            { "fileId": "6000", "format": "file.format.original", "type": "type.file.image.png",
              "downloadUrl": "\(missingFileURL(extension: "png"))" },
            { "fileId": "6001", "format": "file.format.converted", "type": "type.file.image.png",
              "downloadUrl": "\(photo.absoluteString)" }
            """)
        let opened = expectation(description: "the next copy shows")
        vc.viewModel?.onImagePreviewStateChanged = { state in
            if state == .loaded { opened.fulfill() }
        }

        vc.loadRecord()

        wait(for: [opened], timeout: 10)
    }

    func testPDF_HasItsSizeWhenTheDocumentArrives() throws {
        // A PDF view that gets its document before its first layout starts scrolled down by the top
        // bars' height, and the jump to page 1 cannot undo that when it runs before the layout.
        let pdf = try writeTemporaryFile(UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).pdfData { $0.beginPage() },
                                         extension: "pdf")
        let vc = try XCTUnwrap(UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController)
        vc.file = FileModel(name: "scan", recordId: 89796, folderLinkId: 137949, archiveNbr: "01on-0009",
                            type: FileType.pdf.rawValue, permissions: [.read])
        vc.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        vc.view.layoutIfNeeded()
        var sizeWhenTheDocumentArrived: CGSize?
        let arrived = expectation(forNotification: .PDFViewDocumentChanged, object: nil) { notification in
            sizeWhenTheDocumentArrived = (notification.object as? PDFView)?.bounds.size
            return true
        }

        vc.loadPDF(withURL: pdf)

        wait(for: [arrived], timeout: 10)
        XCTAssertEqual(sizeWhenTheDocumentArrived, CGSize(width: 402, height: 874))
    }

    func testRetryTap_RestartsOnlyFromTheFailureCard() {
        // A tap while a file is still loading must not restart the load under the live player.
        let overlay = ImagePreviewStateOverlayView()
        var retries = 0
        overlay.onRetryTapped = { retries += 1 }

        overlay.render(.loadingFullRes(hasThumbnail: false))
        overlay.perform(NSSelectorFromString("overlayTapped"))
        XCTAssertEqual(retries, 0)

        overlay.render(.failed(hasThumbnail: false))
        overlay.perform(NSSelectorFromString("overlayTapped"))
        XCTAssertEqual(retries, 1)
    }

    // MARK: - Download

    func testDownloadFile_IsTheOriginal_WhenTheServerListsTheAccessCopyFirst() {
        let record = makeRecordWithFiles("\(audioAccessCopyJSON), \(audioOriginalJSON)", recordType: FileType.audio.rawValue)

        XCTAssertEqual(DownloadManagerGCD().fileVO(forRecordVO: record, fileType: .audio)?.format, "file.format.original")
    }

    private func makeVideoVM() -> FilePreviewViewModel {
        FilePreviewViewModel(file: FileModel(name: "clip.mov", recordId: 89793, folderLinkId: 137946,
                                             archiveNbr: "01on-0006", type: FileType.video.rawValue,
                                             permissions: [.read]))
    }

    /// A preview screen that already holds its record, so `loadRecord()` runs with no server call.
    private func makePreviewScreen(type: FileType, files: String) throws -> FilePreviewViewController {
        let vc = try XCTUnwrap(UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController)
        vc.file = FileModel(name: "scan", recordId: 89795, folderLinkId: 137948, archiveNbr: "01on-0008",
                            type: type.rawValue, permissions: [.read])
        let vm = FilePreviewViewModel(file: vc.file)
        vm.recordVO = makeRecordWithFiles(files, recordType: type.rawValue)
        vc.viewModel = vm
        vc.loadViewIfNeeded()
        return vc
    }

    private func writeTemporaryFile(_ data: Data, extension pathExtension: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview-\(UUID().uuidString).\(pathExtension)")
        try data.write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        (view as? UIScrollView) ?? view.subviews.lazy.compactMap { self.firstScrollView(in: $0) }.first
    }

    private func missingFileURL(extension pathExtension: String) -> String {
        FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).\(pathExtension)").absoluteString
    }

    private let videoOriginalJSON = """
    { "fileId": "2000", "size": 900000, "format": "file.format.original",
      "type": "type.file.video.quicktime",
      "fileUrl": "https://cdn/originals/2000",
      "downloadUrl": "https://cdn/originals/2000?response-content-disposition=attachment" }
    """

    private let videoConvertedJSON = """
    { "fileId": "2001", "size": 400000, "format": "file.format.converted",
      "type": "type.file.video.mp4",
      "fileUrl": "https://cdn/converted/2001",
      "downloadUrl": "https://cdn/converted/2001?response-content-disposition=attachment" }
    """

    private let videoAccessCopyJSON = """
    { "fileId": "2002", "size": 300000, "format": "file.format.archivematica.access",
      "type": "type.file.video.mp4",
      "fileUrl": "https://cdn/access_copies/2000.mp4",
      "downloadUrl": "https://cdn/access_copies/2000.mp4?response-content-disposition=clip.mp4" }
    """

    private let videoAccessCopyWithoutLinksJSON = """
    { "fileId": "2002", "size": 300000, "format": "file.format.archivematica.access",
      "type": "type.file.video.mp4" }
    """

    private let videoOriginalWithDownloadLinkOnlyJSON = """
    { "fileId": "2000", "size": 900000, "format": "file.format.original",
      "type": "type.file.video.mp4",
      "downloadUrl": "https://cdn/originals/2000?response-content-disposition=attachment" }
    """

    private let audioOriginalJSON = """
    { "fileId": "3000", "size": 88174598, "format": "file.format.original",
      "type": "type.file.audio.wav",
      "fileUrl": "https://cdn/originals/3000",
      "downloadUrl": "https://cdn/originals/3000?response-content-disposition=attachment" }
    """

    private let unknownFormatJSON = """
    { "fileId": "2003", "size": 120000, "format": "file.format.1920x1080",
      "type": "type.file.video.mp4",
      "fileUrl": "https://cdn/1920/2003.mp4",
      "downloadUrl": "https://cdn/1920/2003.mp4?response-content-disposition=clip.mp4" }
    """

    private let unknownFormatWithoutLinksJSON = """
    { "fileId": "2004", "size": 120000, "format": "file.format.1920x1080",
      "type": "type.file.video.mp4" }
    """

    private let audioAccessCopyJSON = """
    { "fileId": "3001", "size": 39990055, "format": "file.format.archivematica.access",
      "type": "type.file.audio.mp3",
      "fileUrl": "https://cdn/access_copies/3000.mp3",
      "downloadUrl": "https://cdn/access_copies/3000.mp3?response-content-disposition=interview.mp3" }
    """

    private let imageOriginalJSON = """
    { "fileId": "4000", "size": 2808983, "format": "file.format.original",
      "type": "type.file.image.heic",
      "fileUrl": "https://cdn/originals/4000",
      "downloadUrl": "https://cdn/originals/4000?response-content-disposition=attachment" }
    """

    private let imageAccessCopyJSON = """
    { "fileId": "4001", "size": 900000, "format": "file.format.archivematica.access",
      "type": "type.file.image.jpg",
      "fileUrl": "https://cdn/access_copies/4000.jpg",
      "downloadUrl": "https://cdn/access_copies/4000.jpg?response-content-disposition=photo.jpg" }
    """

    private let imageAccessCopyWithPlainLinkOnlyJSON = """
    { "fileId": "4001", "size": 900000, "format": "file.format.archivematica.access",
      "type": "type.file.image.jpg",
      "fileUrl": "https://cdn/access_copies/4000.jpg" }
    """

    private let imageConvertedJSON = """
    { "fileId": "4002", "size": 4718504, "format": "file.format.converted",
      "type": "type.file.image.jpg",
      "fileUrl": "https://cdn/converted/4002",
      "downloadUrl": "https://cdn/converted/4002?response-content-disposition=attachment" }
    """

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

// MARK: - Image preview state machine

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

    // MARK: - Thumbnail failure while full-res is pending

    /// A transient thumbnail failure must not paint the failure card while the full-res pipeline can
    /// still deliver — it downgrades to the no-thumbnail loading state instead.
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

    // MARK: - V2 public-root resolution for the publish destination
    // Archives, matched by `archiveNbr`, to `rootFolderId`, to its public-root child. Any failure
    // returns nil so publish falls back to the V1 `getPublicRoot`.

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

// MARK: - ImagePreviewViewController fitted-geometry invariant
// Pins what the atomic swap relies on: `newImageLoaded()` always fits the current image to the
// current scrollView frame, so applying it before the blur lifts gives the right size at once.

final class ImagePreviewViewControllerGeometryTests: XCTestCase {

    /// A loaded controller with a fixed scrollView frame and no layout passes, so `setZoomScale()`
    /// reads exactly the frame set here.
    private func makeVC(width: CGFloat = 400, height: CGFloat = 800) -> ImagePreviewViewController {
        let vc = ImagePreviewViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        vc.loadViewIfNeeded()
        vc.scrollView.frame = vc.view.bounds
        return vc
    }

    /// A solid image whose point size equals the given dimensions, at scale 1 so a large size doesn't
    /// allocate a screen-scale bitmap. Only points matter to the geometry under test.
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

    /// An original smaller than the screen needs a fit scale above 1, which the default
    /// `maximumZoomScale` of 1.0 clamps — so the image renders native and shrinks as the blur lifts.
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

    /// Geometry can first be computed against a smaller frame during pager preload, so
    /// `newImageLoaded()` must refit the current image to the current frame when the full-res lands.
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
