//
//  AuthenticationManagerTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 16.03.2023.
//

import XCTest
@testable import Permanent

class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    var mockAuthRepo: AuthRepository!
    var mockAccountRepo: AccountRepository!
    var mockArchivesRepo: ArchivesRepository!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        authManager = nil
        mockAuthRepo = nil
        mockAccountRepo = nil
        
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.loginResponse = .success(LoginResponse.mock())
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockArchivesDataSource = MockArchivesRemoteDataSource()
        mockArchivesDataSource.getAccountArchivesResult = .success([ArchiveVO(archiveVO: ArchiveVOData.mock())])
        mockArchivesDataSource.changeArchiveResult = .success(true)
        mockArchivesRepo = ArchivesRepository(remoteDataSource: mockArchivesDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, archivesRepository: mockArchivesRepo)

        let expectation = XCTestExpectation(description: "Login Success")
        
        authManager.login(withUsername: "test@example.com", password: "test1234") { status in
            switch status {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Expected success but got a different status")
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }

    func testLoginFailure() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.loginResponse = .failure(NSError(domain: "MockError", code: -1, userInfo: nil))
        
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        mockAccountRepo = AccountRepository()
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        let expectation = XCTestExpectation(description: "Login Failure")
        
        authManager.login(withUsername: "test@example.com", password: "test1234") { status in
            switch status {
            case .error(let message):
                XCTAssertEqual(message, "Authorization error")
                expectation.fulfill()
            default:
                XCTFail("Expected error but got a different status")
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testVerify2FASuccess() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.twoFactorResponse = .success(VerifyResponse.mock())
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockArchivesDataSource = MockArchivesRemoteDataSource()
        mockArchivesDataSource.getAccountArchivesResult = .success([ArchiveVO(archiveVO: ArchiveVOData.mock())])
        mockArchivesDataSource.changeArchiveResult = .success(true)
        mockArchivesRepo = ArchivesRepository(remoteDataSource: mockArchivesDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, archivesRepository: mockArchivesRepo)

        authManager.mfaSession = MFASession(email: "test@example.com", methodType: .mfa)

        let expectation = XCTestExpectation(description: "2FA Verification Success")

        authManager.verify2FA(code: "123456") { status in
            switch status {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Expected success but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testVerify2FAFailure() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.loginResponse = .success(LoginResponse(results: nil, isSuccessful: nil, actionFailKeys: nil, isSystemUp: nil, systemMessage: nil, sessionID: nil, createdDT: nil, updatedDT: nil))
        
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        mockAccountRepo = AccountRepository()
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        authManager.mfaSession = MFASession(email: "test@example.com", methodType: .mfa)

        let expectation = XCTestExpectation(description: "2FA Verification Failure")

        authManager.verify2FA(code: "123456") { status in
            switch status {
            case .error(let message):
                XCTAssertEqual(message, "Authorization error")
                expectation.fulfill()
            default:
                XCTFail("Expected error but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testForgotPasswordSuccess() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.forgotPasswordResponse = .success(ForgotPasswordResponse(results: nil, isSuccessful: true, actionFailKeys: nil, isSystemUp: nil, systemMessage: nil, sessionID: nil, createdDT: nil, updatedDT: nil))
        
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        mockAccountRepo = AccountRepository()
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        let expectation = XCTestExpectation(description: "Forgot Password Success")

        authManager.forgotPassword(withEmail: "test@example.com") { status in
            switch status {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Expected success but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testForgotPasswordFailure() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthDataSource.forgotPasswordResponse = .failure(NSError(domain: "MockError", code: -1, userInfo: nil))
        
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        mockAccountRepo = AccountRepository()
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        let expectation = XCTestExpectation(description: "Forgot Password Failure")

        authManager.forgotPassword(withEmail: "test@example.com") { status in
            switch status {
            case .error(let message):
                XCTAssertEqual(message, "Sorry for the inconvenience, the action could not be completed please try again.")
                expectation.fulfill()
            default:
                XCTFail("Expected error but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSignUpSuccess() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountDataSource.createAccountResponse = .success((SignUpResponse(token: "some_token"), AccountVOData.mock()))
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        let credentials = SignUpV2Credentials(name: "Test User", email: "test@example.com", password: "test1234", optIn: true)

        let expectation = XCTestExpectation(description: "Sign Up Success")

        authManager.signUp(with: credentials) { status in
            switch status {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Expected success but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSignUpFailure() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountDataSource.createAccountResponse = .failure(NSError(domain: "MockError", code: -1, userInfo: nil))
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)

        let credentials = SignUpV2Credentials(name: "Test User", email: "test@example.com", password: "test1234", optIn: true)

        let expectation = XCTestExpectation(description: "Sign Up Failure")

        authManager.signUp(with: credentials) { status in
            switch status {
            case .error(let message):
                XCTAssertEqual(message, .error)
                expectation.fulfill()
            default:
                XCTFail("Expected error but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSaveAndReloadSession() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        let mockArchivesDataSource = MockArchivesRemoteDataSource()
        mockArchivesDataSource.getAccountArchivesResult = .success([ArchiveVO(archiveVO: ArchiveVOData.mock())])
        mockArchivesDataSource.changeArchiveResult = .success(true)
        mockArchivesRepo = ArchivesRepository(remoteDataSource: mockArchivesDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo, archivesRepository: mockArchivesRepo)
        
        // Configure a valid session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()
        authManager.session = session

        // Save the session
        authManager.saveSession()

        // Clear the current session
        authManager.session = nil

        // Reload the session
        let expectation = XCTestExpectation(description: "Save and Reload Failure")
        authManager.reloadSession { success in
            XCTAssertTrue(success, "Session reload should be successful")
            XCTAssertEqual(self.authManager.session?.token, session.token, "Reloaded session token should match the original")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testLogout() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)
        
        // Configure a valid session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()
        authManager.session = session

        // Save the session
        authManager.saveSession()

        // Logout
        authManager.logout()

        // Check if the session is cleared
        XCTAssertNil(authManager.session, "Session should be nil after logout")
        
        let expectation = XCTestExpectation(description: "Logout Failure")
        authManager.reloadSession { success in
            XCTAssertFalse(success, "Session reload should be unsuccessful after logout")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testSyncSessionSuccess() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo)
        
        let expectation = XCTestExpectation(description: "Sync Session Success")

        authManager.syncSession { status in
            switch status {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Expected success but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testSyncSessionFailure() {
        let mockAuthDataSource = MockAuthRemoteDataSource()
        mockAuthRepo = AuthRepository(remoteDataSource: mockAuthDataSource)
        
        let mockAccountDataSource = MockAccountRemoteDataSource()
        mockAccountRepo = AccountRepository(remoteDataSource: mockAccountDataSource)
        
        let mockArchivesDataSource = MockArchivesRemoteDataSource()
        mockArchivesDataSource.getAccountArchivesResult = .failure(NSError(domain: "MockError", code: -1, userInfo: nil))
        mockArchivesRepo = ArchivesRepository(remoteDataSource: mockArchivesDataSource)
        
        authManager = AuthenticationManager(authRepo: mockAuthRepo, accountRepository: mockAccountRepo, archivesRepository: mockArchivesRepo)
        
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()
        authManager.session = session

        let expectation = XCTestExpectation(description: "Sync Session Failure")

        authManager.syncSession { status in
            switch status {
            case .error(let message):
                XCTAssertEqual(message, .errorMessage)
                expectation.fulfill()
            default:
                XCTFail("Expected error but got a different status")
            }
        }

        wait(for: [expectation], timeout: 1)
    }


}
