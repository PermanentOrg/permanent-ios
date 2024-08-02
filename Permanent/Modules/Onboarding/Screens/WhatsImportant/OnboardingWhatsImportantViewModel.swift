//
//  OnboardingWhatsImportantViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingWhatsImportantViewModel: ObservableObject {
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func toggleWhatsImportant(whatsImportant: OnboardingWhatsImportant) {
        if let index = containerViewModel.selectedWhatsImportant.firstIndex(of: whatsImportant) {
            containerViewModel.selectedWhatsImportant.remove(at: index)
        } else {
            containerViewModel.selectedWhatsImportant.append(whatsImportant)
        }
    }
    
    func finishOnboard(_ completionBlock: @escaping ServerResponse) {
        containerViewModel.isLoading = true
        if containerViewModel.creatingNewArchive {
            createArchive(name: containerViewModel.archiveName, type: containerViewModel.archiveType.rawValue) { [weak self] archiveVO, error in
                guard let self = self else { return }
                if let archiveVO = archiveVO, let archiveID = archiveVO.archiveID {
                    self.updateAccount(withDefaultArchiveId: archiveID) { accountVO, error in
                        self.handleAccountUpdate(accountVO: accountVO, archiveVO: archiveVO, completionBlock: completionBlock)
                    }
                } else {
                    self.handleError(completionBlock)
                }
            }
        } else {
            self.addTags { error in
                self.handleTagsAdded(error: error, completionBlock: completionBlock)
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
            AuthenticationManager.shared.login(withUsername: self.containerViewModel.username, password: self.containerViewModel.password) { status in
                if status == .success {
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
                self.containerViewModel.isLoading = false
                if error == nil {
                    completionBlock(.success)
                } else {
                    self.containerViewModel.showAlert = true
                    completionBlock(.error(message: .errorMessage))
                }
            }
        } else {
            self.handleError(completionBlock)
        }
    }

    private func handleError(_ completionBlock: @escaping ServerResponse) {
        self.containerViewModel.isLoading = false
        self.containerViewModel.showAlert = true
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
        containerViewModel.account?.defaultArchiveID = archiveId

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
                    self.containerViewModel.account = account
                    completionBlock(self.containerViewModel.account, nil)
                } else {
                    completionBlock(nil, APIError.invalidResponse)
                }

            default:
                completionBlock(nil, APIError.invalidResponse)
            }
        }
    }

    func addTags(completionBlock: @escaping ((Error?) -> Void)) {
        let goalTags: [String] = containerViewModel.selectedPath.compactMap { $0.tag }
        let whyTags: [String] = containerViewModel.selectedWhatsImportant.compactMap { $0.tag }

        let addTagsOperation = APIOperation(AccountEndpoint.addRemoveTags(archiveType: containerViewModel.archiveType.tag, addGoalTags: goalTags, addWhyTags: whyTags, removeGoalTags: nil, removeWhyTags: nil))
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
                    containerViewModel.allArchives = []
                    containerViewModel.allArchivesVO = archives
                    for archive in archives {
                        if let fullName = archive.archiveVO?.fullName,
                           let status = archive.archiveVO?.status,
                           let archiveID = archive.archiveVO?.archiveID,
                            status == ArchiveVOData.Status.pending || status == ArchiveVOData.Status.ok {
                            containerViewModel.allArchives.append(OnboardingArchive(fullname: containerViewModel.fullName, accessType: AccessRole.roleForValue(archive.archiveVO?.accessRole).groupName, status: status, archiveID: archiveID, thumbnailURL: archive.archiveVO?.thumbURL200 ?? "", isThumbnailGenerated: archive.archiveVO?.thumbStatus != .genAvatar ? true : false))
                        }
                    }
                } else {
                    containerViewModel.allArchives = []
                    containerViewModel.allArchivesVO = []
                }
                
                completionBlock(nil)
                
            default:
                completionBlock(APIError.invalidResponse)
            }
        }
    }
    
}
