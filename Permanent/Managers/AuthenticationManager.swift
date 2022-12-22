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
    let authRepo = AuthRepository()
    
    var token: String? {
        return session?.token
    }
    
    var session: PermSession? {
        didSet {
            PermSession.currentSession = session
        }
    }
    
    var mfaSession: MFASession?
    
    init() {
        NotificationCenter.default.addObserver(forName: APIRequestDispatcher.sessionExpiredNotificationName, object: nil, queue: nil) { [self] notification in
            logout()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [self] (notification) in
            saveSession()
        }
    }
    
    func reloadSession(_ completion: @escaping ((Bool) -> Void)) {
        if let session = try? keychainHandler.savedSession(),
            let selectedArchive = session.selectedArchive {
            self.session = session
            
            changeArchive(selectedArchive) { success, error in
                completion(success)
            }
        } else {
            logout()
            completion(false)
        }
    }
    
    func login(withUsername username: String, password: String, then handler: @escaping (LoginStatus) -> Void) {
        authRepo.login(withUsername: username, password: password) { [self] result in
            switch result {
            case .success(let loginResponse):
                if loginResponse.isSuccessful == true,
                   let token = loginResponse.results?.first?.data?.first?.tokenVO?.value {
                    let accountVO = loginResponse.results?.first?.data?.first?.accountVO
                    let archiveVO = loginResponse.results?.first?.data?.first?.archiveVO
                    
                    let syncResult = syncSession(withToken: token, accountVO: accountVO, archiveVO: archiveVO)
                    switch syncResult {
                    case .success: handler(.success)
                    case .error(let message): handler(.error(message: message))
                    }
                } else if let message = loginResponse.results?.first?.message?.first,
                          let loginError = LoginError(rawValue: message) {
                    if loginError == .mfaToken {
                        handler(.mfaToken)
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
        guard let twoFactorId = mfaSession?.twoFactorId else {
            handler(.error(message: .errorMessage))
            return
        }
        
        authRepo.login(withTwoFactorId: twoFactorId, code: code) { [self] result in
            switch result {
            case .success(let loginResponse):
                guard let token = loginResponse.token else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                let syncResult = syncSession(withToken: token, accountVO: nil, archiveVO: nil)
                switch syncResult {
                case .success: handler(.success)
                case .error(let message): handler(.error(message: message))
                }
            case .failure(_):
                handler(.error(message: "Authorization error".localized()))
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
        session = nil
        keychainHandler.clearSession()
        
        Messaging.messaging().deleteFCMToken(forSenderID: googleServiceInfo.gcmSenderId) { _ in }
    }
    
    func syncSession(withToken token: String, accountVO: AccountVOData?, archiveVO: ArchiveVOData?) -> RequestStatus {
        session = PermSession(token: token)
        
        session?.account = accountVO
        session?.selectedArchive = archiveVO
        
        if accountVO != nil {
            PreferencesManager.shared.set(1, forKey: Constants.Keys.StorageKeys.modelVersion)
            
            saveSession()
            
            return .success
        } else {
            session = nil
            
            return .error(message: "Authorization error".localized())
        }
    }
    
    func changeArchive(_ archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(false, APIError.unknown)
            return
        }
        
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: archiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                
                completionBlock(true, nil)
                return
                
            case .error:
                completionBlock(false, APIError.invalidResponse)
                return
                
            default:
                completionBlock(false, APIError.invalidResponse)
                return
            }
        }
    }
}
