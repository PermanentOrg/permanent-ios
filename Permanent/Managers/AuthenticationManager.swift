//
//  AuthenticationManager.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.02.2022.
//

import UIKit
import KeychainSwift
import AppAuth
import FirebaseMessaging

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    var keychainHandler = SessionKeychainHandler()
    
    var authState: OIDAuthState? {
        return session?.authState
    }
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var session: PermSession?
    
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
    
    func performLoginFlow(fromPresentingVC presentingVC: UIViewController, completion: @escaping ServerResponse) {
        guard let authorizationEndpoint = URL(string: APIEnvironment.defaultEnv.authorizationURL),
            let tokenEndpoint = URL(string: APIEnvironment.defaultEnv.tokenURL),
            let bundleId = Bundle.main.bundleIdentifier,
            let redirectURL = URL(string: bundleId + "://auth-redirect") else {
            completion(.error(message: .errorMessage))
            return
        }
        
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint)
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: authServiceInfo.clientId,
            clientSecret: authServiceInfo.clientSecret,
            scopes: ["offline_access"],
            redirectURL: redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingVC) { [self] authState, error in
            if let authState = authState {
                session = PermSession(authState: authState)
                
                syncSession { [self] status in
                    if status == .success {
                        saveSession()
                        
                        completion(.success)
                    } else {
                        completion(.error(message: "Authorization error".localized()))
                    }
                }
            } else {
                session = nil
                
                completion(.error(message: "Authorization error".localized()))
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
    
    func syncSession(then handler: @escaping ServerResponse) {
        isLoggedIn { [self] status in
            if status == .success {
                getSessionAccount { [self] status, account in
                    if status == .success {
                        guard let account = account else {
                            handler(.error(message: .errorMessage))
                            return
                        }
                        session?.account = account

                        if let _: Int = account.defaultArchiveID {
                            refreshCurrentArchive { success, archive in
                                if success {
                                    self.session?.selectedArchive = archive
                                    handler(.success)
                                } else {
                                    handler(.error(message: .errorMessage))
                                }
                            }
                        } else {
                            handler(.success)
                        }
                    } else {
                        handler(.error(message: .errorMessage))
                    }
                }
            } else {
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    func isLoggedIn(then handler: @escaping (LoginStatus) -> Void) {
        let loginOperation = APIOperation(AuthenticationEndpoint.verifyAuth)
        
        let apiDispatch = APIRequestDispatcher(networkSession: APINetworkSession())
        apiDispatch.ignoresMFAWarning = true
        loginOperation.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<NoDataModel> = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
    
    func getSessionAccount(then handler: @escaping ((RequestStatus, AccountVOData?) -> Void)) {
        let op = APIOperation(AccountEndpoint.getSessionAccount)
        
        let apiDispatch = APIRequestDispatcher(networkSession: APINetworkSession())
        op.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<AccountVO> = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage), nil)
                    return
                }

                if model.isSuccessful == true {
                    PreferencesManager.shared.set(1, forKey: Constants.Keys.StorageKeys.modelVersion)
                    
                    if let accountVO = model.results.first?.data?.first?.accountVO {
                        handler(.success, accountVO)
                    } else {
                        handler(.error(message: .errorMessage), nil)
                    }
                } else {
                    handler(.error(message: .errorMessage), nil)
                }

            case .error:
                handler(.error(message: .errorMessage), nil)

            default:
                break
            }
        }
    }
    
    func refreshCurrentArchive(_ updateHandler: @escaping ((Bool, ArchiveVOData?) -> Void)) {
        getAccountArchives { [self] archives, error in
            if error != nil {
                updateHandler(false, nil)
                return
            }
            
            let hasDefault = archives?.contains(where: { archive in
                archive.archiveVO?.status == ArchiveVOData.Status.ok
            }) ?? false
            
            if hasDefault, let defaultArchive = archives?.first(where: { $0.archiveVO?.archiveID == session?.account.defaultArchiveID && $0.archiveVO?.status != .pending })?.archiveVO {
                session?.selectedArchive = defaultArchive
                
                updateHandler(true, defaultArchive)
            } else {
                updateHandler(true, nil)
            }
        }
    }
    
    func getAccountArchives(_ completionBlock: @escaping (([ArchiveVO]?, Error?) -> Void) ) {
        guard let accountId: Int = session?.account.accountID else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: Int(accountId)))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                let accountArchives = model.results.first?.data
                
                completionBlock(accountArchives, nil)
                return
                
            case .error:
                completionBlock(nil, APIError.invalidResponse)
                return
                
            default:
                completionBlock(nil, APIError.invalidResponse)
                return
            }
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
