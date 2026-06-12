//
//  FolderNavigationViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent

class FolderNavigationViewModelTests: XCTestCase {
    var sut: FolderNavigationViewModel!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRootDisplayName() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)
        
        XCTAssertEqual(sut.displayName, workspaceName)
    }
    
    func testChildDisplayName() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)
        
        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder)
        
        XCTAssertEqual(sut.displayName, childFolder.name)
    }
    
    func testRootBackButton() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)
        
        XCTAssertFalse(sut.hasBackButton)
    }
    
    func testChildBackButton() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)
        
        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder)
        
        XCTAssertTrue(sut.hasBackButton)
    }
    
    func testPushNavigation() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)

        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])

        expectation(forNotification: FolderNavigationViewModel.didUpdateFolderStackNotification, object: sut) { notification in
            return true
        }

        sut.pushFolder(childFolder)

        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.folderStack, [childFolder])
    }

    func testPopNavigation() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)

        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder)

        expectation(forNotification: FolderNavigationViewModel.didUpdateFolderStackNotification, object: sut) { notification in
            return true
        }

        sut.popFolder()

        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.folderStack, [])
    }

    func testPopToFolderNavigation() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)

        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder)
        let childFolder1 = FileModel(name: "Test2", recordId: 333, folderLinkId: 113, archiveNbr: "ooo-014", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder1)
        let childFolder2 = FileModel(name: "Test3", recordId: 444, folderLinkId: 114, archiveNbr: "ooo-015", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder2)

        expectation(forNotification: FolderNavigationViewModel.didUpdateFolderStackNotification, object: sut) { notification in
            return true
        }

        sut.popToFolder(childFolder)

        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.folderStack, [childFolder])
    }

    func testOverPopNavigation() {
        let workspaceName = "Private Files"
        sut = FolderNavigationViewModel(workspaceName: workspaceName, workspace: .privateFiles)

        let childFolder = FileModel(name: "Test1", recordId: 222, folderLinkId: 112, archiveNbr: "ooo-013", type: "type.folder.private", permissions: [])
        sut.pushFolder(childFolder)

        expectation(forNotification: FolderNavigationViewModel.didUpdateFolderStackNotification, object: sut) { notification in
            return true
        }

        sut.popFolder()
        sut.popFolder()
        sut.popFolder()

        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.folderStack, [])
    }
}
