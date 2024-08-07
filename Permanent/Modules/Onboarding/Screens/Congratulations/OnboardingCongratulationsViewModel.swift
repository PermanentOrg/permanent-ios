//
//  OnboardingCongratulationsViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingCongratulationsViewModel: ObservableObject {
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
        if containerViewModel.creatingNewArchive {
            containerViewModel.allArchives = []
            containerViewModel.allArchivesVO = []
            self.getAccountArchives { error in
                self.containerViewModel.isLoading = false
                if error != nil {
                    self.containerViewModel.showAlert = true
                }
            }
        }
    }
    
    func getAccountArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        containerViewModel.isLoading = true
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            containerViewModel.isLoading = false
            completionBlock(APIError.unknown)
            return
        }

        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            self?.containerViewModel.isLoading = false
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
                           status == ArchiveVOData.Status.ok {
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
