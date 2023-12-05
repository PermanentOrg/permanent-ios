//
//  EditDateAndTimeViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.09.2023.

import Foundation
import XCTest
@testable import Permanent

class EditDateAndTimeViewModelTests: XCTestCase {
    
    var viewModel: EditDateAndTimeViewModel!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testGetCommonDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter2.timeZone = TimeZone(secondsFromGMT: 0)

        let date1 = dateFormatter.string(from: Date(timeIntervalSinceNow: -1000))
        let date2 = dateFormatter2.string(from: Date(timeIntervalSinceNow: -1000))

        viewModel = EditDateAndTimeViewModel(selectedFiles: [
            FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: nil, displayDT: date2, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner),
            FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: nil, displayDT: date2, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner),
            FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: nil, displayDT: date2, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner)
        ], hasUpdates: .constant(false))
        let commonDate = dateFormatter.string(from: viewModel.getCommonDate())

        XCTAssertEqual(commonDate, date1, "getCommonDate() should return the common date when all dates are the same")
        
        let date4 = dateFormatter.string(from: Date())
        viewModel.selectedFiles.append(FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: nil, displayDT: date4, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner))
        
        let newCommonDate = viewModel.getCommonDate().description
        
        XCTAssertNotEqual(newCommonDate, date1, "getCommonDate() should not return the common date when all dates are not the same")
    }

    func testApplyChanges() {
        let expectation = XCTestExpectation(description: "Changes applied")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let date1 = dateFormatter.string(from: Date(timeIntervalSinceNow: -1000))

        viewModel = EditDateAndTimeViewModel(selectedFiles: [
            FileModel(model: ItemVO(folderID: nil, archiveNbr: nil, archiveID: nil, displayName: nil, displayDT: date1, displayEndDT: nil, derivedDT: nil, derivedEndDT: nil, note: nil, special: nil, itemVODescription: nil, sort: nil, locnID: nil, timeZoneID: nil, view: nil, viewProperty: nil, thumbArchiveNbr: nil, imageRatio: nil, type: nil, thumbStatus: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, status: nil, publicDT: nil, parentFolderID: nil, folderLinkType: nil, folderLinkVOS: nil, accessRole: nil, position: nil, shareDT: nil, pathAsFolderLinkID: nil, pathAsText: nil, folderLinkID: nil, parentFolderLinkID: nil, parentFolderVOS: nil, parentArchiveNbr: nil, pathAsArchiveNbr: nil, childFolderVOS: nil, recordVOS: nil, locnVO: nil, timezoneVO: nil, directiveVOS: nil, sharedArchiveVOS: nil, tagVOS: nil, folderSizeVO: nil, attachmentRecordVOS: nil, hasAttachments: nil, childItemVOS: nil, shareVOS: nil, accessVOS: nil, archiveArchiveNbr: nil, recordID: nil, returnDataSize: nil, posStart: nil, posLimit: nil, uploadAccountID: nil, derivedCreatedDT: nil, uploadFileName: nil, size: nil, metaToken: nil, refArchiveNbr: nil, fileStatus: nil, processedDT: nil, folderArchiveID: nil, fileVOS: nil, textDataVOS: nil, archiveVOS: nil, saveAs: nil, isAttachment: nil, uploadURI: nil, fileDurationInSecs: nil, batchNbr: nil, recordExifVO: nil, createdDT: nil, updatedDT: nil), archiveThumbnailURL: nil, sharedByArchive: nil, permissions: [.ownership], accessRole: .owner)
        ], hasUpdates: .constant(false))

        viewModel.applyChanges()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertTrue(self.viewModel.changesWereSaved, "Changes should be saved after applyChanges() is called")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }    
}
