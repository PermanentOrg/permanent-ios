//
//  ShareExtensionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 19.07.2022.
//

import Foundation
import XCTest

@testable import Permanent

class ShareExtensionTests: XCTestCase {
    var sut: ShareExtensionViewModel!
    let archiveNegativeTests = ArchiveVOData(childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil, accessRole: nil, fullName: nil, spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil, itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil, archiveID: nil, publicDT: nil, archiveNbr: nil, view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, createdDT: nil, updatedDT: nil, status: nil)
    
    let archivePositiveTests = ArchiveVOData(childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil, accessRole: "access.role.owner", fullName: "test name", spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil, itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil, archiveID: 1653, publicDT: "2021-01-27T19:48:08", archiveNbr: "00in-0000", view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: "00in-000v", type: "type.archive.person", thumbStatus: ArchiveVOData.Status.ok, imageRatio: nil, thumbURL200: "https://stagingcdn.permanent.org/00in-0000.thumb.w200?t=1686306811&Expires=1686306811&Signature=ZXjq08upvH73kyiLZJb-IYlSO4Jz6SaICjGBwHlL-UaQqpd1VAK6KWKnkIQtrLgsfhdkUhwa-TZT5tBSOhFDoeXfxOSLEEF19ml0W~rhyWjXpxhbMhqCL3s43lQ4p0uTeo4KuGXxx6-egFIZK2Z-5hzL52e5tpUJ6r5gENiiSL5r02ZapGmnKDN-UmF6vxaGLYrIAFZ5CpIuV6zCLjaKjLl-P2Ehp~LVTogJF9Tq7vibVTwYcagN4dnO9iDRp4u2alv0SceW2n8NavGaby1tnvQekVnqajbL0Utl1s3kUxiZ2V9VQmGrNRrZ4RRC8lB1xG8hDlb4GpUaQ0H86xiESg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL500: "https://stagingcdn.permanent.org/00in-0000.thumb.w500?t=1686306811&Expires=1686306811&Signature=e5W18KBakMSwIr5EHohYgHf3Nz23VA7eb6-x-3D1NH6Lsq-hxJyIHf9CTCmcksK-HR-CJKyrnIDjA2frUwpT274sPQ4fqVbXh~Od5i7Nh2gv9Gogs73z2QZ5a4Vrnuxhl6ncxWlVixs8AiUu~3ZgjfGQjmk2YODr8aIfp2siAg3SoN0NG1tHQ5AY7QfzrnXRCx55-~g3DaPcU8nuOfhwHAmlQzzvkortQIT2v2OP81~Kh8FW64go7Da~L~4BLPclq2xBcgl9Nk3NKMDIsCPVcVOOOTODz5yvwUbrhxZ7MmPHSxaGxLe8hvJqbrWP~hWgcouM-BLMvFupsRe1thYQhA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL1000: "https://stagingcdn.permanent.org/00in-0000.thumb.w1000?t=1686306811&Expires=1686306811&Signature=Y72DJ9LSrpWQIy2UkUWGil6ZkKaOl2CDJMD9mhxKjl7uPgDpcb3h8KKnjI34~1GyRgsDbB~rE2-TjhO2y7zm2YMfhHEu7yggh8F8wpVBJnETi-O4R0sceWu3pgeSXkyQ5rW~I3mkGPRV8IyoC2s1ByTN1Tsk0s9zGVyGZ3YleJMxikKt3YRM~PEOE69d414aVlI8RxPRkwnHl10T51V5lpTRHANUkuGlt0UclXfMbNkv3aS2r50Ejyj3nbML48oVXXzuwswLnY5GQ0FAq-kPggPlDI-7WSAmozkVHscsO5RE1FUiYNy-TqhKBPE~hk6BDd70n9cMyDr~O2ac9IhoUg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL2000: "https://stagingcdn.permanent.org/00in-0000.thumb.w2000?t=1686306811&Expires=1686306811&Signature=Bay2a-H0hfxh91Tzdz3MmK6sZBuCkK0TTuu54nhQojMqbXzlFZ-Hxqchcixa0lweYW41v4iRJBymD49af92VMlFZYgDwmw8ER6P3iofgGI99y8nMaPGrMsZNV834p-xiZsgD53WLnuR7m5hEOy588-EBYqZjTp9pBCAKaPV-5IcjngvNOh6LcYmX~9kvWchG~NMamkmRLZ0mb5wGNtjny6ZCMcuCC5ta4hdro~NYhGCOqEnz9d35ofjdSqorxIB2gyX2mpIJsyYy9DoEIB5hFwQIgUP9DMZexEB3Bj1sArP5HJ54IKYwqsvXSy64EQMGHSlSMRiu7FAqvttaUhyINg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbDT: "2023-06-09T10:33:31", createdDT: "2021-01-27T19:48:08", updatedDT: "2022-07-07T07:45:44", status: ArchiveVOData.Status.ok)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        positiveTestInit()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        
        try super.tearDownWithError()
    }
    
    func positiveTestInit() {
        sut = ShareExtensionViewModel()
    }
    
    func negativeTestInit() {
        sut = ShareExtensionViewModel()
    }
    
    func testArchiveName() throws {
        let parameterForTest = "The test name Archive"
        
        XCTAssertEqual(sut.archiveName(), parameterForTest)
    }
    
    func testArchiveNameNegative() throws {
        let parameterForTest = "Archive name was not found"
        negativeTestInit()
        
        XCTAssertEqual(sut.archiveName(), parameterForTest)
    }
    
    func testArchiveThumbnailUrl() throws {
        let parameterForTest = "https://stagingcdn.permanent.org/00in-0000.thumb.w1000?t=1686306811&Expires=1686306811&Signature=Y72DJ9LSrpWQIy2UkUWGil6ZkKaOl2CDJMD9mhxKjl7uPgDpcb3h8KKnjI34~1GyRgsDbB~rE2-TjhO2y7zm2YMfhHEu7yggh8F8wpVBJnETi-O4R0sceWu3pgeSXkyQ5rW~I3mkGPRV8IyoC2s1ByTN1Tsk0s9zGVyGZ3YleJMxikKt3YRM~PEOE69d414aVlI8RxPRkwnHl10T51V5lpTRHANUkuGlt0UclXfMbNkv3aS2r50Ejyj3nbML48oVXXzuwswLnY5GQ0FAq-kPggPlDI-7WSAmozkVHscsO5RE1FUiYNy-TqhKBPE~hk6BDd70n9cMyDr~O2ac9IhoUg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"
        
        XCTAssertEqual(sut.archiveThumbnailUrl(), parameterForTest)
    }
    
    func testArchiveThumbnailUrlNegative() throws {
        let parameterForTest: String? = nil
        negativeTestInit()
        
        XCTAssertEqual(sut.archiveThumbnailUrl(), parameterForTest)
    }
    
    func testHasUploadPermission() throws {
        let parameterForTest = true
        
        XCTAssertEqual(sut.hasUploadPermission(), parameterForTest)
    }
    
    func testHasUploadPermissionNegative() throws {
        let parameterForTest = false
        negativeTestInit()
        
        XCTAssertEqual(sut.hasUploadPermission(), parameterForTest)
    }
    
    func testCellConfigurationParametersNegative() throws {
        guard let url = URL(string: "http://www.test.com") else { return }
        let file = FileInfo.init(withURL: url, named: "", folder: FolderInfo(folderId: -1, folderLinkId: -1))
        let parameterForTest: ShareExtensionCellConfiguration = (nil, "", nil)
        negativeTestInit()
        
        XCTAssert(sut.cellConfigurationParameters(file: file) == parameterForTest)
    }
}
