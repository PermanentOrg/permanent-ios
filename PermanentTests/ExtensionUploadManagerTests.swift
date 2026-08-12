//
//  ExtensionUploadManagerTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.07.2022.
//

import Foundation

@testable import Permanent
import XCTest

class ExtensionUploadManagerTests: XCTestCase {
    var sut: ExtensionUploadManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = ExtensionUploadManager()
        // Start every test from an empty queue (drops both the coordinated file
        // and any legacy UserDefaults key), since the store is shared on disk.
        sut.clearSavedFiles()
    }

    override func tearDownWithError() throws {
        sut.clearSavedFiles()
        sut = nil

        try super.tearDownWithError()
    }

    private func makeFile(_ name: String) -> FileInfo {
        FileInfo(withURL: URL(fileURLWithPath: "/tmp/\(name)"),
                 named: name,
                 folder: FolderInfo(folderId: -1, folderLinkId: -1))
    }

    func testSaveRetrieveFiles() throws {
        let fileInfo = [
            FileInfo(withURL: URL(fileURLWithPath: "path"), named: "test1", folder: FolderInfo(folderId: -1, folderLinkId: -1)),
            FileInfo(withURL: URL(fileURLWithPath: "path2"), named: "test2", folder: FolderInfo(folderId: -1, folderLinkId: -1))
        ]

        try sut.save(files: fileInfo)

        let retrievedFiles = try sut.savedFiles()

        XCTAssertEqual(fileInfo, retrievedFiles)
    }

    func testClearFiles() throws {
        let fileInfo = [
            FileInfo(withURL: URL(fileURLWithPath: "path"), named: "test1", folder: FolderInfo(folderId: -1, folderLinkId: -1)),
            FileInfo(withURL: URL(fileURLWithPath: "path2"), named: "test2", folder: FolderInfo(folderId: -1, folderLinkId: -1))
        ]

        try sut.save(files: fileInfo)

        sut.clearSavedFiles()

        let retrievedFiles = try sut.savedFiles()

        XCTAssertTrue(retrievedFiles.isEmpty)
    }

    /// `append` merges the new files ahead of what's already queued, atomically —
    /// this is the path the ShareExtension uses, replacing read-then-save.
    func testAppendMergesAheadOfExistingQueue() throws {
        let existing = makeFile("existing")
        let incoming = makeFile("incoming")

        try sut.save(files: [existing])
        try sut.append([incoming])

        XCTAssertEqual(try sut.savedFiles(), [incoming, existing])
    }

    func testAppendToEmptyQueue() throws {
        let file = makeFile("solo")

        try sut.append([file])

        XCTAssertEqual(try sut.savedFiles(), [file])
    }

    /// Clearing a subset (what the main app does after enqueuing) removes only the
    /// named files and leaves the rest — including anything appended in between.
    func testClearSpecificFilesLeavesTheRest() throws {
        let a = makeFile("a")
        let b = makeFile("b")
        let c = makeFile("c")

        try sut.save(files: [a, b, c])
        try sut.clearSavedFiles([b])

        XCTAssertEqual(try sut.savedFiles(), [a, c])
    }

    /// The upgrade path: a queue an older build left in the legacy UserDefaults key must be read as a
    /// fallback and carried into the coordinated file, never dropped.
    func testMigratesLegacyUserDefaultsQueueWithoutLoss() throws {
        let legacy = makeFile("pending-from-old-build")

        // Seed the legacy store exactly as the previous implementation did, with
        // no coordinated file present (setUp cleared it).
        NSKeyedArchiver.setClassName("Permanent.FileInfo", for: FileInfo.self)
        NSKeyedArchiver.setClassName("Permanent.FolderInfo", for: FolderInfo.self)
        try PreferencesManager().setNonPlistObject(NSArray(array: [legacy]),
                                                   forKey: ExtensionUploadManager.savedFilesKey)

        // Read falls back to the legacy key before any write migrates it.
        XCTAssertEqual(try sut.savedFiles(), [legacy], "legacy queue should be readable before migration")

        // First write migrates: the new file is queued ahead of the legacy one…
        let incoming = makeFile("newly-shared")
        try sut.append([incoming])
        XCTAssertEqual(try sut.savedFiles(), [incoming, legacy], "legacy file must survive the first write")

        // …and the legacy key is retired.
        let leftover: Data? = PreferencesManager().getValue(forKey: ExtensionUploadManager.savedFilesKey)
        XCTAssertNil(leftover, "legacy UserDefaults key should be cleared after migration")
    }

    /// The point of the write barrier: concurrent read-modify-writes must not lose updates. In-process
    /// only, but the same coordinator barrier serializes the cross-process case.
    func testConcurrentAppendsDoNotLoseUpdates() throws {
        let count = 40

        DispatchQueue.concurrentPerform(iterations: count) { i in
            try? self.sut.append([self.makeFile("concurrent-\(i)")])
        }

        let saved = try sut.savedFiles()
        XCTAssertEqual(saved.count, count, "every concurrent append must survive the coordinated barrier")

        let names = Set(saved.map { $0.name })
        XCTAssertEqual(names.count, count, "no files dropped or duplicated under contention")
        for i in 0..<count {
            XCTAssertTrue(names.contains("concurrent-\(i)"), "lost concurrent-\(i)")
        }
    }
}
