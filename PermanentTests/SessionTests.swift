//
//  SessionTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 27.07.2022.
//

import Foundation
@testable import Permanent
import XCTest
import KeychainSwift

class SessionTests: XCTestCase {
    var sut: SessionKeychainHandler!
    
    let accountVO = AccountVOData(accountID: 1000, primaryEmail: "email@email.com", fullName: "Test Account", address: "Street", address2: nil, country: nil, city: nil, state: nil, zip: nil, primaryPhone: nil, level: nil, apiToken: nil, betaParticipant: nil, facebookAccountID: nil, googleAccountID: nil, status: nil, type: nil, emailStatus: nil, phoneStatus: nil, notificationPreferences: nil, agreed: nil, optIn: nil, emailArray: nil, inviteCode: nil, rememberMe: nil, keepLoggedIn: nil, accessRole: nil, spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, changePrimaryEmail: nil, changePrimaryPhone: nil, createdDT: "2021-01-27T19:48:08", updatedDT: nil)
    
    let archiveVO = ArchiveVOData(childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil, accessRole: "access.role.owner", fullName: "test name", spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil, itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil, archiveID: 1653, publicDT: "2021-01-27T19:48:08", archiveNbr: "00in-0000", view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: "00in-000v", type: "type.archive.person", thumbStatus: ArchiveVOData.Status.ok, imageRatio: nil, thumbURL200: "https://stagingcdn.permanent.org/00in-0000.thumb.w200?t=1686306811&Expires=1686306811&Signature=ZXjq08upvH73kyiLZJb-IYlSO4Jz6SaICjGBwHlL-UaQqpd1VAK6KWKnkIQtrLgsfhdkUhwa-TZT5tBSOhFDoeXfxOSLEEF19ml0W~rhyWjXpxhbMhqCL3s43lQ4p0uTeo4KuGXxx6-egFIZK2Z-5hzL52e5tpUJ6r5gENiiSL5r02ZapGmnKDN-UmF6vxaGLYrIAFZ5CpIuV6zCLjaKjLl-P2Ehp~LVTogJF9Tq7vibVTwYcagN4dnO9iDRp4u2alv0SceW2n8NavGaby1tnvQekVnqajbL0Utl1s3kUxiZ2V9VQmGrNRrZ4RRC8lB1xG8hDlb4GpUaQ0H86xiESg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL500: "https://stagingcdn.permanent.org/00in-0000.thumb.w500?t=1686306811&Expires=1686306811&Signature=e5W18KBakMSwIr5EHohYgHf3Nz23VA7eb6-x-3D1NH6Lsq-hxJyIHf9CTCmcksK-HR-CJKyrnIDjA2frUwpT274sPQ4fqVbXh~Od5i7Nh2gv9Gogs73z2QZ5a4Vrnuxhl6ncxWlVixs8AiUu~3ZgjfGQjmk2YODr8aIfp2siAg3SoN0NG1tHQ5AY7QfzrnXRCx55-~g3DaPcU8nuOfhwHAmlQzzvkortQIT2v2OP81~Kh8FW64go7Da~L~4BLPclq2xBcgl9Nk3NKMDIsCPVcVOOOTODz5yvwUbrhxZ7MmPHSxaGxLe8hvJqbrWP~hWgcouM-BLMvFupsRe1thYQhA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL1000: "https://stagingcdn.permanent.org/00in-0000.thumb.w1000?t=1686306811&Expires=1686306811&Signature=Y72DJ9LSrpWQIy2UkUWGil6ZkKaOl2CDJMD9mhxKjl7uPgDpcb3h8KKnjI34~1GyRgsDbB~rE2-TjhO2y7zm2YMfhHEu7yggh8F8wpVBJnETi-O4R0sceWu3pgeSXkyQ5rW~I3mkGPRV8IyoC2s1ByTN1Tsk0s9zGVyGZ3YleJMxikKt3YRM~PEOE69d414aVlI8RxPRkwnHl10T51V5lpTRHANUkuGlt0UclXfMbNkv3aS2r50Ejyj3nbML48oVXXzuwswLnY5GQ0FAq-kPggPlDI-7WSAmozkVHscsO5RE1FUiYNy-TqhKBPE~hk6BDd70n9cMyDr~O2ac9IhoUg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbURL2000: "https://stagingcdn.permanent.org/00in-0000.thumb.w2000?t=1686306811&Expires=1686306811&Signature=Bay2a-H0hfxh91Tzdz3MmK6sZBuCkK0TTuu54nhQojMqbXzlFZ-Hxqchcixa0lweYW41v4iRJBymD49af92VMlFZYgDwmw8ER6P3iofgGI99y8nMaPGrMsZNV834p-xiZsgD53WLnuR7m5hEOy588-EBYqZjTp9pBCAKaPV-5IcjngvNOh6LcYmX~9kvWchG~NMamkmRLZ0mb5wGNtjny6ZCMcuCC5ta4hdro~NYhGCOqEnz9d35ofjdSqorxIB2gyX2mpIJsyYy9DoEIB5hFwQIgUP9DMZexEB3Bj1sArP5HJ54IKYwqsvXSy64EQMGHSlSMRiu7FAqvttaUhyINg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", thumbDT: "2023-06-09T10:33:31", createdDT: "2021-01-27T19:48:08", updatedDT: "2022-07-07T07:45:44", status: ArchiveVOData.Status.ok)
    
    let token: String = "token"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = SessionKeychainHandler()
    }
    
    override func tearDownWithError()  throws {
        sut = nil
        
        try super.tearDownWithError()
    }
    
    func testSaveSession() throws {
        let session = PermSession(token: token)
        session.account = accountVO
        session.selectedArchive = archiveVO
        
        try sut.saveSession(session)
        
        let savedSession = try sut.savedSession()
        
        XCTAssert(session.account.accountID == savedSession?.account.accountID)
        XCTAssert(session.selectedArchive?.archiveID == savedSession?.selectedArchive?.archiveID)
        
        sut.clearSession()
    }
    
    func testClearSession() throws {
        let session = PermSession(token: token)
        
        try sut.saveSession(session)
        
        sut.clearSession()
        
        XCTAssertNil(try sut.savedSession())
    }
}
