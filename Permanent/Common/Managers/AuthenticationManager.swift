//
//  AuthenticationManager.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.02.2022.
//

import UIKit
import KeychainSwift
import FirebaseMessaging

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    var keychainHandler = SessionKeychainHandler()
    let authRepo: AuthRepository
    let accountRepository: AccountRepository
    let archivesRepository: ArchivesRepository
    
    var token: String? {
        return session?.token
    }
    
    var session: PermSession? {
        didSet {
            PermSession.currentSession = session
        }
    }
    
    var mfaSession: MFASession?
    
    init(authRepo: AuthRepository = AuthRepository(), accountRepository: AccountRepository = AccountRepository(), archivesRepository: ArchivesRepository = ArchivesRepository()) {
        self.authRepo = authRepo
        self.accountRepository = accountRepository
        self.archivesRepository = archivesRepository
        
        NotificationCenter.default.addObserver(forName: APIRequestDispatcher.sessionExpiredNotificationName, object: nil, queue: nil) { [self] notification in
            logout()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [self] (notification) in
            saveSession()
        }
    }
    
    func reloadSession(_ completion: @escaping ((Bool) -> Void)) {
        do {
            if let session = try keychainHandler.savedSession() {
                // Set the session first
                self.session = session
                
                if let selectedArchive = session.selectedArchive {
                    // Try to change to the saved archive on the server
                    changeArchive(selectedArchive) { [weak self] result in
                        switch result {
                        case .success(_):
                            // Server successfully changed to the archive, keep the selectedArchive
                            self?.session?.selectedArchive = selectedArchive
                            self?.saveSession()
                        
                            completion(true)
                            
                        case .failure:
                            // Server call failed, but still keep the session with the saved selectedArchive
                            // This ensures the user's last selected archive is preserved even if offline
                            self?.session?.selectedArchive = selectedArchive
                            self?.saveSession()
                            
                            completion(true)
                        }
                    }
                } else {
                    // No saved archive, session is still valid but will need to get default archive
                    self.session = session
                    completion(true)
                }
            } else {
                logout()
                completion(false)
            }
        } catch {
            logout()
            completion(false)
        }
    }
    
    func login(withUsername username: String, password: String, then handler: @escaping (LoginStatus) -> Void) {
        logout()
        
        authRepo.login(withUsername: username, password: password) { [self] result in
            switch result {
            case .success(let loginResponse):
                if loginResponse.isSuccessful == true,
                   let token = loginResponse.results?.first?.data?.first?.tokenVO?.value,
                   let account = loginResponse.results?.first?.data?.first?.accountVO {
                    session = PermSession(token: token)
                    session?.account = account
                    
                    syncSession { [self] status in
                        if status == .success {
                            saveSession()
                            
                            handler(.success)
                        } else {
                            handler(.error(message: "Authorization error".localized()))
                        }
                    }
                } else if let message = loginResponse.results?.first?.message?.first,
                          let loginError = LoginError(rawValue: message) {
                    if loginError == .mfaToken {
                        mfaSession = MFASession(email: username, methodType: CodeVerificationType.mfa)
                        handler(.mfaToken)
                    } else if loginError == .unknown {
                        handler(.unknown)
                    } else {
                        handler(.error(message: loginError.description))
                    }
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .failure( _):
                handler(.error(message: "Authorization error".localized()))
            }
        }
    }
    
    func verify2FA(code: String, then handler: @escaping ServerResponse) {
        guard let email = mfaSession?.email,
        let method = mfaSession?.methodType else {
            handler(.error(message: .errorMessage))
            return
        }
        
        authRepo.login(withEmail: email, code: code, type: method) { [self] result in
            switch result {
            case .success(let response):
                guard let token = response.results?.first?.data?.first?.tokenVO?.value,
                 let account = response.results?.first?.data?.first?.accountVO else {
                    handler(.error(message: .errorMessage))
                    return
                }
                mfaSession = nil

                session = PermSession(token: token)
                session?.account = account

                syncSession { [self] status in
                    if status == .success {
                        saveSession()

                        handler(.success)
                    } else {
                        handler(.error(message: "Authorization error".localized()))
                    }
                }
            case .failure(_):
                handler(.error(message: "Authorization error".localized()))
            }
        }
    }
    
    func forgotPassword(withEmail email: String, then handler: @escaping ServerResponse) {
        authRepo.forgotPassword(withEmail: email) { result in
            switch result {
            case .success(_):
                handler(.success)
            case .failure(_):
                handler(.error(message: "Sorry for the inconvenience, the action could not be completed please try again.".localized()))
            }
        }
    }
    
    func signUp(with credentials: SignUpV2Credentials, then handler: @escaping (RequestStatus) -> Void) {
        logout()
        
        accountRepository.createAccount(fullName: credentials.name, primaryEmail: credentials.email, password: credentials.password, optIn: credentials.optIn, inviteCode: credentials.inviteCode) { [self] result in
            switch result {
            case .success((let signupResponse, let account)):
                let token = signupResponse.token
                session = PermSession(token: token)
                session?.account = account
                
                saveSession()
                handler(.success)
                
            default:
                handler(.error(message: .error))
            }
        }
    }
    
    func saveSession() {
        guard let session = session else {
            return
        }

        do {
            try keychainHandler.saveSession(session)
        } catch {
            print("Failed to save auth data")
        }
    }
    
    func logout() {
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))

        session = nil
        keychainHandler.clearSession()
        UserDefaults.standard.set(false, forKey: Constants.Keys.StorageKeys.memberChecklistWasShown)
        
        Messaging.messaging().deleteFCMToken(forSenderID: googleServiceInfo.gcmSenderId) { _ in }
    }
    
    func syncSession(then handler: @escaping ServerResponse) {
        if let _: Int = session?.account.defaultArchiveID {
            refreshCurrentArchive { result in
                switch result {
                case .success(let archive):
                    // Only update session if we don't have a current archive
                    if self.session?.selectedArchive == nil {
                        self.session?.selectedArchive = archive
                    } else {
                        // Check if the current archive is the same as default
                        let currentArchive = self.session?.selectedArchive
                        let refreshedArchive = archive
                        
                        if let currentArchive = currentArchive,
                           let refreshedArchive = refreshedArchive,
                           currentArchive.archiveID == refreshedArchive.archiveID {
                            
                            // CRITICAL FIX: Don't overwrite user's archive selection with server data
                            // The user's local session contains their intended archive state
                            // Check if server has different data
                            if currentArchive.fullName != refreshedArchive.fullName {
                                print("🔴 ARCHIVE_DEBUG: ⚠️⚠️⚠️ ARCHIVE NAME MISMATCH DETECTED!")
                            } else {
            
                                // Only update with server data if names match (safe update for other fields)
                                self.session?.selectedArchive = refreshedArchive
                            }
                        } else {
                            print("🔴 ARCHIVE_DEBUG: User has different archive selected (not default), preserving user's choice")
                            print("🔴 ARCHIVE_DEBUG: - NOT updating session selectedArchive to preserve user's current selection")
                            print("🔴 ARCHIVE_DEBUG: - This prevents overriding user's active editing session")
                        }
                    }
                    
                    // Notify that session sync is complete so UI can refresh
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("SessionSyncCompleted"), object: nil)
                    }
                    
                    handler(.success)
                    
                case .failure(_):
                    handler(.error(message: .errorMessage))
                }
            }
        } else {
            // Still post notification even when no default archive
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SessionSyncCompleted"), object: nil)
            }
            
            handler(.success)
        }
    }
    
    func refreshCurrentArchive(_ updateHandler: @escaping (Result<ArchiveVOData?, Error>) -> Void) {
        getAccountArchives { [self] result in
            switch result {
            case .failure(let error):
                updateHandler(.failure(error))
                
            case .success(let archives):
                let hasDefault = archives.contains(where: { archive in
                    archive.archiveVO?.status == ArchiveVOData.Status.ok
                })
                
                if hasDefault, let defaultArchive = archives.first(where: { $0.archiveVO?.archiveID == session?.account.defaultArchiveID && $0.archiveVO?.status != .pending })?.archiveVO {
                    session?.selectedArchive = defaultArchive
                    
                    updateHandler(.success(defaultArchive))
                } else {
                    updateHandler(.success(nil))
                }
            }
        }
    }
    
    func getAccountArchives(_ completionBlock: @escaping (Result<[ArchiveVO], Error>) -> Void) {
        guard let accountId: Int = session?.account.accountID else {
            completionBlock(.failure(APIError.unknown))
            return
        }

        archivesRepository.getAccountArchives(accountId: accountId) { result in
            completionBlock(result)
        }
    }
    
    func changeArchive(_ archive: ArchiveVOData, _ completionBlock: @escaping (Result<Bool, Error>) -> Void) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(.failure(APIError.unknown))
            return
        }

        archivesRepository.changeArchive(archiveId: archiveId, archiveNbr: archiveNbr) { [weak self] result in
            switch result {
            case .success(_):
                // Update session and save when server confirms the change
                self?.updateSelectedArchive(archive)
                completionBlock(.success(true))
                
            case .failure(let error):
                completionBlock(.failure(error))
            }
        }
    }
    
    func updateSelectedArchive(_ archive: ArchiveVOData) {
        session?.selectedArchive = archive
        saveSession()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: Notification.Name("ArchivesViewModel.didChangeArchiveNotification"), object: nil)
    }

}
