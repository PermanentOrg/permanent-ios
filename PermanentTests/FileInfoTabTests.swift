//
//  FileInfoTabTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Permanent

/// The Info tab's row list for each role, the Details list, the name and description save rules, the Date row
/// after the date screen saves, and where the picture leads.
@MainActor
struct FileInfoTabTests {
    private typealias CellType = FileDetailsViewController.CellType
    private let ownArchiveId = 5

    // MARK: - Rows

    @Test("A member with the edit right gets the four rows, boxed, then the tags row")
    func editorRows() throws {
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit])

        let rows = screen.infoRows()
        #expect(rows.map(\.kind) == [.name, .description, .date, .location])
        #expect(rows.allSatisfy { $0.style == .boxed })
        #expect(rows.map(\.isSet) == [true, false, false, false])
        #expect(cells(of: screen) == [.name, .description, .date, .location, .tags])
    }

    @Test("A set location puts the map right after its row")
    func editorRowsWithCoordinates() throws {
        let screen = try makeScreen(fields: #""displayName": "B", \#(locationJSON)"#, permissions: [.read, .edit])

        let location = try #require(screen.infoRows().first { $0.kind == .location })
        #expect(location.isSet)
        #expect(location.text.contains("Yamanakako"))
        #expect(cells(of: screen) == [.name, .description, .date, .location, .locationMap, .tags])
    }

    @Test("A member without the edit right sees only the rows that hold data, plain, name first")
    func viewerRows() throws {
        let nameOnly = try makeScreen(fields: #""displayName": "C""#, permissions: [.read])
        #expect(nameOnly.infoRows().map(\.kind) == [.name])
        #expect(nameOnly.infoRows().allSatisfy { $0.style == .plain })
        #expect(cells(of: nameOnly) == [.name])

        let nameAndDate = try makeScreen(fields: #""displayName": "C", "displayTime": "1985-10-23T17:00:00""#, permissions: [.read])
        #expect(nameAndDate.infoRows().map(\.kind) == [.name, .date])
        #expect(cells(of: nameAndDate) == [.name, .date])

        let nameAndPlace = try makeScreen(fields: #""displayName": "C", \#(locationJSON)"#, permissions: [.read])
        #expect(nameAndPlace.infoRows().map(\.kind) == [.name, .location])
        #expect(cells(of: nameAndPlace) == [.name, .location, .locationMap])

        let described = try makeScreen(fields: #""displayName": "C", "description": "Picnic""#, permissions: [.read])
        #expect(described.infoRows().map(\.kind) == [.name, .description])
    }

    @Test("The tags row shows a viewer only the tags the record has")
    func viewerTags() throws {
        let tagged = try makeScreen(fields: #""displayName": "C", "tags": [{ "tagId": "1", "name": "hike" }]"#, permissions: [.read])
        #expect(cells(of: tagged) == [.name, .tags])

        let untagged = try makeScreen(fields: #""displayName": "C", "tags": []"#, permissions: [.read])
        #expect(cells(of: untagged) == [.name])
    }

    @Test("The Details tab keeps its eight rows")
    func detailsRows() {
        #expect(FileDetailsViewController.detailsCells == [.uploaded, .lastModified, .created, .fileCreated, .size, .fileType, .originalFileName, .originalFileType])
    }

    @Test("Before the record arrives, an editor already sees the four boxed rows with the file's name")
    func rowsBeforeTheRecordArrives() {
        let file = FileModel(name: "Pending.jpg", recordId: 42, folderLinkId: 7, archiveNbr: "0005-0000", type: "type.record.image", permissions: [.read, .edit])
        let viewModel = OfflinePreviewViewModel(file: file)

        #expect(viewModel.infoRows().map(\.text).first == "Pending.jpg")
        #expect(viewModel.infoRows().count == 4)
    }

    // MARK: - Saving

    @Test("An empty or unchanged name sends nothing and answers false")
    func nameRevertRules() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let emptyName = await save(name: "", in: screen)
        #expect(emptyName == false)
        let sameName = await save(name: "August_Hike_003", in: screen)
        #expect(sameName == false)
        #expect(server.patches.isEmpty)
        #expect(screen.name == "August_Hike_003")
    }

    @Test("A new name goes out as displayName and answers true")
    func newNameIsSent() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let renamed = await save(name: "A renamed", in: screen)
        #expect(renamed == true)
        #expect(server.patches.map(\.recordId) == [301])
        #expect(server.patches.first?.fields["displayName"] as? String == "A renamed")
        #expect(screen.name == "A renamed")
    }

    @Test("A failed save answers false and keeps the old name")
    func failedSave() async throws {
        let server = FakeServer(patchSucceeds: false)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let failed = await save(name: "A renamed", in: screen)
        #expect(failed == false)
        #expect(server.patches.count == 1, "the PATCH was tried")
        #expect(server.v1Names == ["A renamed"], "then the V1 failsafe")
        #expect(screen.name == "August_Hike_003")
    }

    @Test("A description follows the same rules")
    func descriptionRules() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "A", "description": "Picnic""#, permissions: [.read, .edit], server: server)

        let emptyDescription = await save(description: "", in: screen)
        #expect(emptyDescription == false)
        let sameDescription = await save(description: "Picnic", in: screen)
        #expect(sameDescription == false)
        #expect(server.patches.isEmpty)
        let newDescription = await save(description: "Lunch", in: screen)
        #expect(newDescription == true)
        #expect(server.patches.first?.fields["description"] as? String == "Lunch")
    }

    // MARK: - The Date row's zone

    @Test("The Date row ends in the zone's short name when the record carries one, else in the string's offset", arguments: [
        (#""displayTime": "1985-10-23T17:00:00+01:00", "location": { "timezone": "Europe/Paris" }"#, "October 23, 1985 • 5PM +01"),
        (#""displayTime": "1985-07-23T17:00:00-04:00", "location": { "timezone": "America/New_York" }"#, "July 23, 1985 • 5PM EDT"),
        (#""displayTime": "1985-10-23T17:00:00+03:00""#, "October 23, 1985 • 5PM +03"),
        (#""displayTime": "1985-10-23T17:00:00""#, "October 23, 1985 • 5PM"),
        (#""displayTime": "1985-10-23", "location": { "timezone": "Europe/Paris" }"#, "October 23, 1985")
    ])
    func dateRowWithZone(fields: String, expected: String) throws {
        let screen = try makeScreen(fields: #""displayName": "B", "# + fields, permissions: [.read, .edit])

        #expect(screen.infoRowDate()?.text == expected)
        #expect(screen.infoRows().first { $0.kind == .date }?.text == expected)
    }

    @Test("The record's zone survives the V2 bridge; a location without one, or no location, gives none")
    func zoneSurvivesTheBridge() throws {
        let zoned = try record(#""displayName": "B", "location": { "id": "7", "timezone": "Europe/Paris" }"#)
        let placed = try record(#""displayName": "B", \#(locationJSON)"#)
        let bare = try record(#""displayName": "B""#)

        #expect(zoned.recordVO?.timezone == "Europe/Paris")
        #expect(placed.recordVO?.timezone == nil)
        #expect(bare.recordVO?.timezone == nil)
    }

    // MARK: - The Date row's qualifiers and range

    @Test("A date range gives the Date row a From and a To line, read as one element, and a row one line taller")
    func dateRowForARange() throws {
        let fields = #""displayName": "B", "displayTime": "1985-10-23T16:16:00+01:00/1985-11-23", "location": { "timezone": "Europe/Paris" }"#
        let screen = try makeScreen(fields: fields, permissions: [.read, .edit])
        let row = try #require(screen.infoRows().first { $0.kind == .date })
        let defaultSize = UITraitCollection(preferredContentSizeCategory: .large)

        #expect(row.lines.map(\.caption) == ["From", "To"])
        #expect(row.lines.map(\.text) == ["October 23, 1985 • 4:16 PM +01", "November 23, 1985"])
        #expect(row.labelDetail == nil)
        #expect(row.lineCount == 2)
        #expect(row.accessibilityLabel == "Date, From October 23, 1985 • 4:16 PM +01, To November 23, 1985")
        #expect(FileInfoRowModel.height(for: .boxed, lines: 2, compatibleWith: defaultSize) == 104)
        #expect(FileInfoRowModel.height(for: .plain, lines: 2, compatibleWith: defaultSize) == 80)
        #expect(FileInfoRowModel.height(for: .boxed, lines: 1, compatibleWith: defaultSize) == 72)
    }

    @Test("A hosted range row is as tall as its model says", arguments: FileInfoRowModel.Style.allCases)
    func hostedRangeRowMatchesTheModelHeight(style: FileInfoRowModel.Style) throws {
        let text = try #require(DisplayTimeText(displayTime: "1985-10-23~/1985-11-23~", legacy: nil))
        let model = FileInfoRowModel(date: text, style: style)
        // Measured outside a window, where no safe area is added to the row.
        let host = UIHostingController(rootView: FileInfoRow(model: model))
        host.loadViewIfNeeded()

        let fitted = host.sizeThatFits(in: CGSize(width: 342, height: 1000)).height
        let expected = FileInfoRowModel.height(for: style, lines: model.lineCount, compatibleWith: host.traitCollection)

        #expect(model.labelDetail == "Approximate")
        #expect(abs(fitted - expected) <= 1, "fitted \(fitted), model \(expected)")
    }

    @Test("The qualifier words follow the label of one date, and an unknown date reads as such for every role", arguments: [
        (#""displayTime": "1985-10-23%""#, "Approximate • Uncertain", "October 23, 1985"),
        (#""displayTime": "1985~""#, "Approximate", "1985"),
        (#""displayTime": "XXXX-XX-XX""#, nil, "Unknown date and time"),
        (#""displayTime": "../1985-11-23""#, nil, "Before November 23, 1985")
    ])
    func dateRowWithQualifiers(fields: String, detail: String?, expected: String) throws {
        let editor = try makeScreen(fields: #""displayName": "B", "# + fields, permissions: [.read, .edit])
        let viewer = try makeScreen(fields: #""displayName": "B", "# + fields, permissions: [.read])
        let row = try #require(editor.infoRows().first { $0.kind == .date })

        #expect(row.labelDetail == detail)
        #expect(row.text == expected)
        #expect(row.lineCount == 1)
        #expect(row.accessibilityLabel == ["Date", detail, expected].compactMap { $0 }.joined(separator: ", "))
        #expect(viewer.infoRows().first { $0.kind == .date }?.text == expected)
    }

    // MARK: - After the date screen

    @Test("After the date screen saves, the Date row shows the new date and the list is told to refresh")
    func dateRowAfterTheDateScreen() throws {
        let before = try record(#""displayName": "B", "displayTime": "1985-10-23T17:00:00""#)
        let after = try record(#""displayName": "B", "displayTime": "2001-02-03T09:30:00""#)
        let viewModel = RereadingPreviewViewModel(file: try file(from: before, permissions: [.read, .edit]))
        viewModel.recordVO = before
        viewModel.nextRecord = after
        let details = try #require(UIViewController.create(withIdentifier: .fileDetailsOnTap, from: .main) as? FileDetailsViewController)
        details.file = viewModel.file
        details.viewModel = viewModel
        let navigation = FilePreviewNavigationController(rootViewController: details)
        navigation.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        navigation.view.layoutIfNeeded()
        details.view.layoutIfNeeded()
        #expect(details.infoRows.first { $0.kind == .date }?.text == "October 23, 1985 • 5PM")

        details.dateScreenDidClose(saved: true)

        #expect(details.infoRows.first { $0.kind == .date }?.text == "February 3, 2001 • 9:30 AM")
        #expect(navigation.hasChanges)
        let reopened = EditDateAndTimeViewModel(file: details.file, record: details.recordVO, hasUpdates: .constant(false))
        #expect(details.file.displayTime == "1985-10-23T17:00:00", "the row the screen opened with is stale")
        #expect(reopened.entry.edtfString == "2001-02-03T09:30:00", "the sheet reopens on the saved date")
    }

    // MARK: - The picture

    @Test("The picture asks the list for the file's preview when a list opened the screen; under a preview it only goes back")
    func pictureTapRoutes() throws {
        let viewModel = try makeScreen(fields: #""displayName": "B""#, permissions: [.read, .edit])
        let details = try #require(UIViewController.create(withIdentifier: .fileDetailsOnTap, from: .main) as? FileDetailsViewController)
        details.file = viewModel.file
        details.viewModel = viewModel
        let list = ListSpy()
        details.delegate = list
        let navigation = FilePreviewNavigationController(rootViewController: details)
        navigation.hasChanges = true
        details.loadViewIfNeeded()

        details.collectionView(details.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))

        #expect(list.previewRequests.map(\.file) == [viewModel.file])
        #expect(list.previewRequests.first?.hasChanges == true)

        navigation.closeTransition = FileInfoCloseTransition(to: nil)
        details.collectionView(details.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))

        #expect(list.previewRequests.count == 1, "under a preview the picture only glides back")
    }

    @Test("The preview glides in over a list-opened Info screen, and its X returns to the list")
    func previewGlidesInOverTheInfoScreen() async throws {
        let scene = try await infoScreenInWindow()
        defer { scene.window.isHidden = true }
        let (preview, pager, page) = try pagerWithLoadedPage(for: scene.viewModel.file, delegate: scene.spy)

        scene.details.showPreview(preview)
        await wait { scene.navigation.view.window == nil && !preview.isBeingPresented }

        #expect(scene.details.presentedViewController === preview)
        #expect(preview.openTransition is FileInfoCloseTransition)
        #expect(pager.currentPage === page)
        #expect(page.thumbnailImageView.image === scene.picture, "a thumbnail-sized picture seeds the slot the glide lands on")
        #expect(preview.chainRoot === scene.list)
        #expect(scene.navigation.view.window == nil, "the Info screen is out of the window once the preview is up")

        pager.closeButtonAction(pager)
        await wait { scene.list.presentedViewController == nil }

        #expect(scene.list.presentedViewController == nil, "the X closes the preview and the Info screen under it")
    }

    @Test("The Info screen's full-size picture becomes the preview's loaded photo: no blur, no download")
    func fullSizePictureIsTheLoadedPhoto() async throws {
        let scene = try await infoScreenInWindow()
        defer { scene.window.isHidden = true }
        let (preview, _, page) = try pagerWithLoadedPage(for: scene.viewModel.file, delegate: scene.spy)
        let pageModel = try makeScreen(fields: #""displayName": "B""#, permissions: [.read, .edit])
        page.viewModel = pageModel
        pageModel.thumbnailDidLoad()
        scene.details.view.layoutIfNeeded()
        scene.details.collectionView.layoutIfNeeded()
        let cell = try #require(scene.details.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FileDetailsTopCollectionViewCell)
        cell.showsFullSize = true

        scene.details.showPreview(preview)
        await wait { scene.navigation.view.window == nil && !preview.isBeingPresented }

        #expect(page.imagePreviewVC?.imageView.image === scene.picture)
        #expect(page.shownPhotoView === page.imagePreviewVC?.imageView, "the glide lands on the zoomable view")
        #expect(page.thumbnailImageView.isHidden)
        #expect(pageModel.imagePreviewState == .loaded, "the blur state is left before it shows")
        page.loadImage(withURL: URL(fileURLWithPath: "/never-downloaded"))
        #expect(page.imagePreviewVC?.imageView.image === scene.picture, "the full-size download is skipped")
    }

    // MARK: - Helpers

    private struct InfoScene {
        let window: UIWindow
        let list: UIViewController
        let navigation: FilePreviewNavigationController
        let details: FileDetailsViewController
        let viewModel: FilePreviewViewModel
        let picture: UIImage
        let spy: ListSpy
    }

    /// A list root in a window with the Info screen presented full screen over it, its slot showing a 2×2 picture.
    private func infoScreenInWindow() async throws -> InfoScene {
        let list = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = list
        window.makeKeyAndVisible()
        let spy = ListSpy()
        let viewModel = try makeScreen(fields: #""displayName": "B""#, permissions: [.read, .edit])
        let navigation = try #require(FileDetailsViewController.navigation(for: viewModel.file, delegate: spy) as? FilePreviewNavigationController)
        let details = try #require(navigation.viewControllers.first as? FileDetailsViewController)
        details.viewModel = viewModel
        let picture = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { $0.fill(CGRect(x: 0, y: 0, width: 2, height: 2)) }
        details.openingImage = picture
        var infoIsUp = false
        list.present(navigation, animated: false) { infoIsUp = true }
        await wait { infoIsUp }
        return InfoScene(window: window, list: list, navigation: navigation, details: details, viewModel: viewModel, picture: picture, spy: spy)
    }

    /// The pager for `file` with its page already loaded, so it asks no server.
    private func pagerWithLoadedPage(for file: FileModel, delegate: ListSpy) throws -> (preview: FilePreviewNavigationController, pager: FilePreviewListViewController, page: FilePreviewViewController) {
        let files = FilesViewModel()
        files.viewModels = [file]
        let preview = FilePreviewListViewController.navigation(for: file, in: files, delegate: delegate)
        let pager = try #require(preview.viewControllers.first as? FilePreviewListViewController)
        let page = try #require(UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController)
        page.file = file
        page.recordLoaded = true
        pager.controllersCache.setObject(page, forKey: 0)
        return (preview, pager, page)
    }

    private let locationJSON = #""location": { "id": "7", "name": "Yamanakako", "city": "Yamanashi", "country": "Japan", "latitude": 35.41, "longitude": 138.87 }"#

    /// A record through the real V2 bridge, as the screen receives it.
    private func record(_ fields: String) throws -> RecordVO {
        let json = """
        { "data": { "recordId": "301", "archiveId": "\(ownArchiveId)", "type": "type.record.image", "folderLinkId": "900", \(fields) } }
        """
        let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
        return try #require(JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)
    }

    private func file(from record: RecordVO, permissions: [Permission]) throws -> FileModel {
        let data = try #require(record.recordVO)
        return FileModel(model: data, permissions: permissions, accessRole: permissions.contains(.edit) ? .editor : .viewer)
    }

    private func makeScreen(fields: String, permissions: [Permission], server: FakeServer? = nil) throws -> FilePreviewViewModel {
        let recordVO = try record(fields)
        let viewModel = OfflinePreviewViewModel(file: try file(from: recordVO, permissions: permissions))
        viewModel.recordVO = recordVO
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        if let server {
            viewModel.patchRecordRequest = { recordId, fields, completion in
                server.patches.append((recordId, fields))
                completion(server.patchSucceeds)
            }
            viewModel.updateV1Request = { params, completion in
                if let name = params.name { server.v1Names.append(name) }
                completion(false)
            }
        }
        return viewModel
    }

    private func cells(of viewModel: FilePreviewViewModel) -> [CellType] {
        FileDetailsViewController.infoCells(rows: viewModel.infoRows(), hasMap: viewModel.infoTabHasMap, hasTags: viewModel.infoTabHasTags)
    }

    private func save(name: String, in viewModel: FilePreviewViewModel) async -> Bool? {
        var outcome: Bool?
        viewModel.saveName(name) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    private func save(description: String, in viewModel: FilePreviewViewModel) async -> Bool? {
        var outcome: Bool?
        viewModel.saveDescription(description) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    /// Lets queued main-thread work run until `done` holds, for at most five seconds.
    private func wait(until done: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !done(), Date() < deadline {
            await Task.yield()
        }
    }

    /// Records each call the screen makes and answers it at once.
    private final class FakeServer {
        let patchSucceeds: Bool
        var patches: [(recordId: Int, fields: [String: Any])] = []
        var v1Names: [String] = []

        init(patchSucceeds: Bool) {
            self.patchSucceeds = patchSucceeds
        }
    }

    /// A list behind the Info screen, noting the previews the picture asks for.
    private final class ListSpy: FilePreviewNavigationControllerDelegate {
        var previewRequests: [(file: FileModel, hasChanges: Bool)] = []

        func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {}
        func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {}
        func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {}

        func filePreviewNavigationControllerRequestsPreview(_ details: UIViewController, file: FileModel, hasChanges: Bool) {
            previewRequests.append((file, hasChanges))
        }
    }

    /// The details view model with the record re-read after a save answered locally, not by the server.
    private class OfflinePreviewViewModel: FilePreviewViewModel {
        override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
            handler(nil)
        }
    }

    /// A re-read hands out the next record, as the server would after the date screen saved.
    private final class RereadingPreviewViewModel: OfflinePreviewViewModel {
        var nextRecord: RecordVO?

        override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
            if let nextRecord { recordVO = nextRecord }
            handler(recordVO)
        }
    }
}
