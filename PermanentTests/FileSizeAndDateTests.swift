//
//  FileSizeAndDateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The line under a row's name in the file lists, "4 MB • Aug. 15, 2023", and its VoiceOver text.
/// August, because iOS versions write September as "Sep." or "Sept.".
struct FileSizeAndDateTests {
    private func child(_ fields: String) throws -> FileModel {
        let json = "{ \"items\": [ { \(fields) } ] }"
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read], accessRole: .viewer)
    }

    @Test("A file shows its size, a dot and its written date")
    func fileShowsSizeAndDate() throws {
        let file = try child("\"recordId\": \"8\", \"type\": \"type.record.image\", \"size\": 4000000, \"displayDate\": \"2023-08-15T00:00:00.000Z\"")
        #expect(file.sizeAndDate == "4 MB • Aug. 15, 2023")
        #expect(file.sizeAndDateForVoiceOver == "4 MB, Aug. 15, 2023")
    }

    @Test("A folder shows only its written date")
    func folderShowsTheDateOnly() throws {
        let folder = try child("\"folderId\": \"10\", \"type\": \"private\", \"size\": 5000000, \"displayTimestamp\": \"2023-08-15T00:00:00.000Z\"")
        #expect(folder.type.isFolder)
        #expect(folder.sizeAndDate == "Aug. 15, 2023")
    }

    @Test("A file with no size shows only its written date", arguments: [0, -1])
    func fileWithNoSizeShowsTheDateOnly(size: Int) throws {
        let file = try child("\"recordId\": \"8\", \"type\": \"type.record.image\", \"size\": \(size), \"displayDate\": \"2023-08-15\"")
        #expect(file.sizeAndDate == "Aug. 15, 2023")
        #expect(file.sizeAndDateForVoiceOver == "Aug. 15, 2023")
    }

    @Test("A file with no date shows only its size, and never a dash")
    func fileWithNoDateShowsTheSizeOnly() throws {
        let file = try child("\"recordId\": \"8\", \"type\": \"type.record.image\", \"size\": 2800000")
        #expect(file.date == "-")
        #expect(file.sizeAndDate == "2.8 MB")
    }

    @Test("The sheet header writes the size the way the row does")
    @MainActor
    func sheetHeaderMatchesTheRow() {
        #expect(FileMenuViewModel.formatFileSize(4_000_000) == FileModel.displaySize(4_000_000))
        #expect(FileModel.displaySize(0) == nil)
    }
}
