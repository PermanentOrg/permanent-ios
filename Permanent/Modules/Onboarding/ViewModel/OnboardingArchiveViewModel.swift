//
//  OnboardingStorageValues.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.04.2024.

import Foundation
import SwiftUI

class OnboardingArchiveViewModel: ObservableObject {
    var username: String
    var password: String
    @Published var archiveType: ArchiveType = .person
    @Published var archiveName: String = ""
    @Published var selectedPath: [OnboardingPath] = []
    @Published var selectedWhatsImportant: [OnboardingWhatsImportant] = []
    @Published var fullName: String
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    var account: AccountVOData?
    
    let welcomeMessage: String = "We’re so glad you’re here!\n\nAt Permanent, it is our mission to provide a safe and secure place to store, preserve, and share the digital legacy of all people, whether that's for you or for your friends, family, interests or organizations.\n\nWe know that starting this journey can sometimes be overwhelming, but don’t worry. We’re here to help you every step of the way."
    
    init(username: String?, password: String?) {
        self.username = username ?? ""
        self.password = password ?? ""
        self.fullName = AuthenticationManager.shared.session?.account.fullName ?? ""
    }
    
    func getIndefiniteArticle() -> String {
        if archiveType == .individual || archiveType == .organization {
            return "an"
        }
        return "a"
    }
    
    func togglePath(path: OnboardingPath) {
        if let index = selectedPath.firstIndex(of: path)
        {
            selectedPath.remove(at: index)
        } else {
            selectedPath.append(path)
        }
    }
    
    func toggleWhatsImportant(whatsImportant: OnboardingWhatsImportant) {
        if let index = selectedWhatsImportant.firstIndex(of: whatsImportant)
        {
            selectedWhatsImportant.remove(at: index)
        } else {
            selectedWhatsImportant.append(whatsImportant)
        }
    }
    
    func finishOnboard(_ completionBlock: @escaping ServerResponse) {
        isLoading = true
        createArchive(name: archiveName, type: archiveType.rawValue) { [self] archiveVO, error in
            if let archiveVO = archiveVO, let archiveID = archiveVO.archiveID {
                updateAccount(withDefaultArchiveId: archiveID) { [self] accountVO, error in
                    if accountVO != nil {
                        changeArchive(archiveVO) { success, error in
                            if success {
//                                AuthenticationManager.shared.refreshCurrentArchive { result in
//                                    if success {


                                                AuthenticationManager.shared.login(withUsername: self.username, password: self.password) { status in
                                                    if status == .success {
                                                        UserDefaults.standard.set(-1, forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
                                                        self.addTags { error in
                                                            self.isLoading = false
                                                            if error == nil {
                                                        completionBlock(.success)
                                                    } else {
                                                        self.showAlert = true
                                                        completionBlock(.error(message: .errorMessage))
                                                    }
                                                }
                                                
                                            } else {
                                                self.isLoading = false
                                                self.showAlert = true
                                                completionBlock(.error(message: .errorMessage))
                                            }
                                        }
                                        
//                                    } else {
//                                        self.isLoading = false
//                                        self.showAlert = true
//                                        completionBlock(.error(message: .errorMessage))
//                                    }
//                                }
                                
          
                            } else {
                                self.isLoading = false
                                self.showAlert = true
                                completionBlock(.error(message: .errorMessage))
                            }
                        }
                    } else {
                        self.isLoading = false
                        self.showAlert = true
                        completionBlock(.error(message: .errorMessage))
                    }
                }
            } else {
                self.isLoading = false
                self.showAlert = true
                completionBlock(.error(message: .errorMessage))
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
                self.setCurrentArchive(archive)
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
    
    func createArchive(name: String, type: String, _ completionBlock: @escaping ((ArchiveVOData?, Error?) -> Void)) {
        let createArchiveOperation = APIOperation(ArchivesEndpoint.create(name: name, type: type))
        createArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                if let archiveVO = model.results[0].data?[0].archiveVO {
                    completionBlock(archiveVO, APIError.invalidResponse)
                } else {
                    completionBlock(nil, nil)
                }
                
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
    
    func updateAccount(withDefaultArchiveId archiveId: Int, _ completionBlock: @escaping ((AccountVOData?, Error?) -> Void)) {
        account?.defaultArchiveID = archiveId
        
        guard let accountVO = AuthenticationManager.shared.session?.account else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let updateAccountOperation = APIOperation(AccountEndpoint.update(accountVO: accountVO))
        updateAccountOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                if let account = model.results[0].data?[0].accountVO {
                    AuthenticationManager.shared.session?.account = account
                    self.account = account
                    completionBlock(self.account, nil)
                } else {
                    completionBlock(nil, APIError.invalidResponse)
                }
                
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
    
    func addTags(completionBlock: @escaping ((Error?) -> Void)) {
        let goalTags: [String] = selectedPath.compactMap({$0.tag})
        let whyTags: [String] = selectedWhatsImportant.compactMap({$0.tag})
        
        let addTagsOperation = APIOperation(AccountEndpoint.addRemoveTags(archiveType: archiveType.tag, addGoalTags: goalTags, addWhyTags: whyTags, removeGoalTags: nil, removeWhyTags: nil))
        addTagsOperation.execute(in: APIRequestDispatcher()) { result in
            completionBlock(nil)
//            switch result {
//            case .json(let response, _):
//                guard
//                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
//                    model.isSuccessful
//                else {
//                    completionBlock(APIError.invalidResponse)
//                    return
//                }
//                completionBlock(nil)
//                
//                return
//                
//            case .error:
//                completionBlock(APIError.invalidResponse)
//                return
//                
//            default:
//                completionBlock(APIError.invalidResponse)
//                return
//            }
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        AuthenticationManager.shared.session?.selectedArchive = archive
    }
}
