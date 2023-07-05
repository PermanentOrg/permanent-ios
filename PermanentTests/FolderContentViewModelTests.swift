//
//  FolderContentViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent

class FolderContentViewModelTests: XCTestCase {
    var sut: FolderContentViewModel!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadFolderData() {
        let rootFolder = FileModel(name: "Root", recordId: 123, folderLinkId: 111, archiveNbr: "ooo-012", type: "type.folder.private", permissions: [])
        
        let folderContent = [
            FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: []),
            FileModel(name: "Test2", recordId: 333, folderLinkId: 113, archiveNbr: "ooo-014", type: "type.folder.private", permissions: []),
            FileModel(name: "Test3", recordId: 444, folderLinkId: 114, archiveNbr: "ooo-015", type: "type.folder.private", permissions: [])
        ]
        let remoteDataSource = FilesRemoteMockDataSource()
        remoteDataSource.folderContentMockFiles = folderContent
        let filesRepo = FilesRepository(remoteDataSource: remoteDataSource)

        sut = FolderContentViewModel(folder: rootFolder, filesRepository: filesRepo)
        XCTAssertEqual(self.sut.files, folderContent)
    }
    
    func testRefreshFolderData() {
        let rootFolder = FileModel(name: "Root", recordId: 123, folderLinkId: 111, archiveNbr: "ooo-012", type: "type.folder.private", permissions: [])
        
        var folderContent = [
            FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: []),
            FileModel(name: "Test2", recordId: 333, folderLinkId: 113, archiveNbr: "ooo-014", type: "type.folder.private", permissions: []),
            FileModel(name: "Test3", recordId: 444, folderLinkId: 114, archiveNbr: "ooo-015", type: "type.folder.private", permissions: [])
        ]
        let remoteDataSource = FilesRemoteMockDataSource()
        remoteDataSource.folderContentMockFiles = folderContent
        let filesRepo = FilesRepository(remoteDataSource: remoteDataSource)

        sut = FolderContentViewModel(folder: rootFolder, filesRepository: filesRepo)
        XCTAssertEqual(self.sut.files, folderContent)
        
        expectation(forNotification: FolderContentViewModel.didUpdateFilesNotification, object: sut) { notification in
            XCTAssertEqual(self.sut.files, folderContent)
            return true
        }
        
        folderContent.append(FileModel(name: "Test4", recordId: 555, folderLinkId: 115, archiveNbr: "ooo-016", type: "type.folder.private", permissions: []))
        remoteDataSource.folderContentMockFiles = folderContent
        sut.refreshFolder()
        
        waitForExpectations(timeout: 5)
    }
}
