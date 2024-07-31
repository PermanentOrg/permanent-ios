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
    @Published var allArchives: [OnboardingArchive] = []
    @Published var allArchivesVO: [ArchiveVO] = []
    @Published var fullName: String
    @Published var isLoading: Bool = false
    @Published var initIsLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var isArchiveAccepted: Bool = false
    var account: AccountVOData?
    
    init(username: String?, password: String?) {
        isLoading = true
        initIsLoading = true
        self.username = username ?? ""
        self.password = password ?? ""
        self.fullName = AuthenticationManager.shared.session?.account.fullName ?? ""
        
        self.getAccountArchives { error in
            self.isLoading = false
            self.initIsLoading = false
            if error != nil {
                self.showAlert = true
            }
        }
    }
    
    func getIndefiniteArticle() -> String {
        if archiveType == .person || archiveType == .organization {
            return "an"
        }
        return "a"
    }
    
    func togglePath(path: OnboardingPath) {
        if let index = selectedPath.firstIndex(of: path) {
            selectedPath.remove(at: index)
        } else {
            selectedPath.append(path)
        }
    }
    
    func toggleWhatsImportant(whatsImportant: OnboardingWhatsImportant) {
        if let index = selectedWhatsImportant.firstIndex(of: whatsImportant) {
            selectedWhatsImportant.remove(at: index)
        } else {
            selectedWhatsImportant.append(whatsImportant)
        }
    }
    
    func finishOnboard(_ completionBlock: @escaping ServerResponse) {
        isLoading = true
        createArchive(name: archiveName, type: archiveType.rawValue) { [weak self] archiveVO, error in
            guard let self = self else { return }
            if let archiveVO = archiveVO, let archiveID = archiveVO.archiveID {
                self.updateAccount(withDefaultArchiveId: archiveID) { accountVO, error in
                    self.handleAccountUpdate(accountVO: accountVO, archiveVO: archiveVO, completionBlock: completionBlock)
                }
            } else {
                self.handleError(completionBlock)
            }
        }
    }

    private func handleAccountUpdate(accountVO: AccountVOData?, archiveVO: ArchiveVOData, completionBlock: @escaping ServerResponse) {
        if accountVO != nil {
            self.changeArchive(archiveVO) { success, error in
                self.handleArchiveChange(success: success, completionBlock: completionBlock)
            }
        } else {
            self.handleError(completionBlock)
        }
    }

    private func handleArchiveChange(success: Bool, completionBlock: @escaping ServerResponse) {
        if success {
            AuthenticationManager.shared.login(withUsername: self.username, password: self.password) { status in
                if status == .success {
                    UserDefaults.standard.set(-1, forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
                    self.addTags { error in
                        self.handleTagsAdded(error: error, completionBlock: completionBlock)
                    }
                } else {
                    self.handleError(completionBlock)
                }
            }
        } else {
            self.handleError(completionBlock)
        }
    }

    private func handleTagsAdded(error: Error?, completionBlock: @escaping ServerResponse) {
        if error == nil {
            self.getAccountArchives { error in
                self.isLoading = false
                if error == nil {
                    completionBlock(.success)
                } else {
                    self.showAlert = true
                    completionBlock(.error(message: .errorMessage))
                }
            }
        } else {
            self.handleError(completionBlock)
        }
    }

    private func handleError(_ completionBlock: @escaping ServerResponse) {
        self.isLoading = false
        self.showAlert = true
        completionBlock(.error(message: .errorMessage))
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
                guard let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder), model.isSuccessful else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                self.setCurrentArchive(archive)
                completionBlock(true, nil)

            default:
                completionBlock(false, APIError.invalidResponse)
            }
        }
    }

    func createArchive(name: String, type: String, _ completionBlock: @escaping ((ArchiveVOData?, Error?) -> Void)) {
        let createArchiveOperation = APIOperation(ArchivesEndpoint.create(name: name, type: type))
        createArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder), model.isSuccessful else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                if let archiveVO = model.results[0].data?[0].archiveVO {
                    completionBlock(archiveVO, nil)
                } else {
                    completionBlock(nil, nil)
                }

            default:
                completionBlock(nil, APIError.invalidResponse)
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
                guard let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder), model.isSuccessful else {
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

            default:
                completionBlock(nil, APIError.invalidResponse)
            }
        }
    }

    func addTags(completionBlock: @escaping ((Error?) -> Void)) {
        let goalTags: [String] = selectedPath.compactMap { $0.tag }
        let whyTags: [String] = selectedWhatsImportant.compactMap { $0.tag }

        let addTagsOperation = APIOperation(AccountEndpoint.addRemoveTags(archiveType: archiveType.tag, addGoalTags: goalTags, addWhyTags: whyTags, removeGoalTags: nil, removeWhyTags: nil))
        addTagsOperation.execute(in: APIRequestDispatcher()) { result in
            completionBlock(nil)
        }
    }

    func setCurrentArchive(_ archive: ArchiveVOData) {
        AuthenticationManager.shared.session?.selectedArchive = archive
    }

    func getAccountArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completionBlock(APIError.unknown)
            return
        }

        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .json(let response, _):
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                        model.isSuccessful else {
                    completionBlock(APIError.invalidResponse)
                    return
                }
                
                if let archives = model.results.first?.data {
                    allArchives = []
                    allArchivesVO = archives
                    for archive in archives {
                        if let fullName = archive.archiveVO?.fullName,
                           let status = archive.archiveVO?.status,
                           let archiveID = archive.archiveVO?.archiveID,
                            status == ArchiveVOData.Status.pending || status == ArchiveVOData.Status.ok {
                            allArchives.append(OnboardingArchive(fullname: fullName, accessType: AccessRole.roleForValue(archive.archiveVO?.accessRole).groupName, status: status, archiveID: archiveID, thumbnailURL: archive.archiveVO?.thumbURL200 ?? "", isThumbnailGenerated: archive.archiveVO?.thumbStatus != .genAvatar ? true : false))
                        }
                    }
                } else {
                    allArchives = []
                    allArchivesVO = []
                }
                
                completionBlock(nil)
                
            default:
                completionBlock(APIError.invalidResponse)
            }
        }
    }
    
    func acceptPendingArchive(archive: OnboardingArchive) {
        isLoading = true
        guard let archiveVO = allArchivesVO.first(where: { $0.archiveVO?.archiveID == archive.archiveID}),
              let archiveVOData = archiveVO.archiveVO else {
            isLoading = false
            showAlert = true
            return
        }
        
        acceptArchiveOperation(archive: archiveVOData, { status, error in
            self.isLoading = false
            if status {
                self.isArchiveAccepted = true
                guard let _ = archiveVOData.archiveID else {
                    self.showAlert = true
                    return
                }
                
                archive.status = .ok
            }
        })
    }
    
    func acceptArchiveOperation(archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let acceptArchiveOperation = APIOperation(ArchivesEndpoint.accept(archiveVO: archive))

        acceptArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                
                self.changeArchive(archive) { success, error in
                    if success {
                        completionBlock(true, nil)
                        return
                    } else {
                        completionBlock(false, APIError.invalidResponse)
                        return
                    }
                }
                
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
