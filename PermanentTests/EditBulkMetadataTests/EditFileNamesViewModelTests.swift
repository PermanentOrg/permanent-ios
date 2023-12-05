//
//  EditFileNamesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.09.2023.

import Foundation

import XCTest
@testable import Permanent
import SwiftUI

class EditFileNamesViewModelTests: XCTestCase {
    var sut: MetadataEditFileNamesViewModel!
    @State var hasUpdates: Bool = false
    
    override func setUp() {
        super.setUp()
        
        let file = FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: "Test file", displayDT: nil, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner)
        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        sut = MetadataEditFileNamesViewModel(tagsRepository: tagsManagementRepository, selectedFiles: [file], hasUpdates: $hasUpdates)
        createMockSession()
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testFileNamePreview() {
        if let firstFileName = sut.fileNamePreview {
            XCTAssertEqual(firstFileName, "Test file", "fileNamePreview should be equal to the name of the first file in selectedFiles")
        } else {
            XCTFail("fileNamePreview should be equal to the name of the first file in selectedFiles")
        }
    }
    
    func createMockSession() {
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()

        AuthenticationManager.shared.session = session
    }
}

