//
//  FolderViewSelectionViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent
import AppAuth

class FolderViewSelectionViewModelTests: XCTestCase {
    var sut: FolderViewSelectionViewModel!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetSorting() {
        let configuration = OIDServiceConfiguration(authorizationEndpoint: URL(string: "permanent.fusionAuth.org")!,
                                                    tokenEndpoint: URL(string: "permanent.fusionAuth.org")!)
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: "authServiceInfo.clientId",
            clientSecret: "authServiceInfo.clientSecret",
            scopes: ["offline_access"],
            redirectURL: URL(string: "org.permanent.permanentArchive://")!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        let authState = OIDAuthState(authorizationResponse: OIDAuthorizationResponse(request: request, parameters: [:]))
        let session = PermSession(authState: authState)
        session.isGridView = false
        
        sut = FolderViewSelectionViewModel(session: session)
        sut.isGridView = false
        
        expectation(forNotification: FolderViewSelectionViewModel.didUpdateFolderViewNotification, object: sut) { notification in
            XCTAssertTrue(self.sut.isGridView)
            return true
        }
        
        sut.isGridView = true
        
        waitForExpectations(timeout: 5)
    }
}
