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
    }
    
    override func tearDownWithError() throws {
        sut = nil
        
        try super.tearDownWithError()
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
        
        XCTAssert(retrievedFiles.isEmpty)
    }
}
