//
//  ChangeDestinationUploadManagerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.10.2023.

import SwiftUI

class ChangeDestinationUploadManagerViewModel: ObservableObject {
    @Published var archiveSelected: ArchiveDropdownMenuOption = ArchiveDropdownMenuOption(archiveName: "", archiveThumbnailAddress: "", archiveAccessRole: "", archiveNbr: "", isArchiveSelected: false)
    
    var accountArchives: [ArchiveVOData]?
    var changedArchive: ArchiveDropdownMenuOption?
    var account: AccountVOData? {
        didSet {
            updateCurrentArchive()
        }
    }
    var defaultArchiveId: Int? { account?.defaultArchiveID }
    
    @Published var allArchives: [ArchiveVOData] = []
    var availableArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveNbr != currentArchive()?.archiveNbr })
    }
    
    var pendingArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.status == ArchiveVOData.Status.pending })
    }
    
    var selectableArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.status == ArchiveVOData.Status.ok })
    }
    
    @Published var archivesList: [ArchiveDropdownMenuOption] = []
    
    init(currentArchive: ArchiveVOData?) {
        updateCurrentArchive()
        updateArchivesList()
    }
    
    func getAccountInfo(_ completionBlock: @escaping ((AccountVOData?, Error?) -> Void)) {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                self.account = model.results[0].data?[0].accountVO
                completionBlock(self.account, nil)
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
    
    func getAccountArchives(_ completionBlock: @escaping (([ArchiveVO]?, Error?) -> Void) ) {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
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
                
                self.allArchives.removeAll()
                accountArchives?.forEach { archive in
                    if let archiveVOData = archive.archiveVO, archiveVOData.status != .pending || archiveVOData.status != .unknown {
                        self.allArchives.append(archiveVOData)
                    }
                }
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
    
    func currentArchive() -> ArchiveVOData? {
        return PermSession.currentSession?.selectedArchive
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        PermSession.currentSession?.selectedArchive = archive
        
        UploadManager.shared.timer?.fire()
        
        updateCurrentArchive()
    }
    
    func changeArchive(_ archiveOption: ArchiveDropdownMenuOption, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        guard let archive: ArchiveVOData = allArchives.filter({ $0.archiveNbr == archiveOption.archiveNbr }).first else {
            completionBlock(false, APIError.clientError)
            return
        }
        
        NotificationCenter.default.post(name: ArchivesViewModel.closeArchiveSettings, object: self, userInfo: nil)
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
    
    func updateArchivesList() {
        getAccountInfo({ [self] account, error in
            if error == nil {
                if let currentArchives = self.accountArchives {
                    allArchives = currentArchives
                    self.accountArchives = nil
                    updateCurrentArchive()
                } else {
                    getAccountArchives { [self] accountArchives, error in
                        if error == nil {
                            updateCurrentArchive()
                        }
                    }
                }
            }
        })
    }
    
    func updateCurrentArchive() {
        if let archive = currentArchive(),
           let archiveName: String = archive.fullName,
           let archiveThumbURL: String = archive.thumbURL500,
           let archiveNbr: String = archive.archiveNbr,
           let archiveGroup: String? = AccessRole.roleForValue(archive.accessRole).groupName,
           let archiveRole: String = archiveGroup {
            archiveSelected = ArchiveDropdownMenuOption(archiveName: "The \(archiveName) Archive", archiveThumbnailAddress: archiveThumbURL, archiveAccessRole: archiveRole, archiveNbr: archiveNbr, isArchiveSelected: true)
            
            if let changedArchive = changedArchive {
                archiveSelected =  ArchiveDropdownMenuOption(archiveName: changedArchive.archiveName, archiveThumbnailAddress: changedArchive.archiveThumbnailAddress, archiveAccessRole: changedArchive.archiveAccessRole, archiveNbr: changedArchive.archiveNbr, isArchiveSelected: true)
            }
            
            archivesList = selectableArchives.map({ archive in
                let archiveName = "The \(archive.fullName ?? "") Archive"
                let archiveThumbnail = archive.thumbURL500 ?? ""
                let archiveRole = AccessRole.roleForValue(archive.accessRole).groupName
                var isArchiveSelected: Bool = false
                if archiveSelected.archiveNbr == archive.archiveNbr {
                    isArchiveSelected = true
                }
                return ArchiveDropdownMenuOption(archiveName: archiveName, archiveThumbnailAddress: archiveThumbnail, archiveAccessRole: archiveRole,archiveNbr: archive.archiveNbr ?? "", isArchiveSelected: isArchiveSelected)
            })
        }
    }
}
