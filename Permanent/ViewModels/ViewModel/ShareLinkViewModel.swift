//
//  ShareLinkViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

typealias ShareLinkResponse = (SharebyURLVOData?, String?) -> Void

class ShareLinkViewModel: NSObject, ViewModelInterface {
    static let didRevokeShareLinkNotifName = NSNotification.Name("ShareLinkViewModel.didRevokeShareLinkNotif")
    static let didUpdateSharesNotifName = NSNotification.Name("ShareLinkViewModel.didUpdateSharesNotifName")
    static let didCreateShareLinkNotifName = NSNotification.Name("ShareLinkViewModel.didCreateShareLinkNotifName")
    static let didUpdateShareLinkRoleNotifName = NSNotification.Name("ShareLinkViewModel.didUpdateShareLinkRoleNotifName")
    
    var fileViewModel: FileModel!
    var shareVO: SharebyURLVOData?
    
    var recordVO: RecordVOData?
    var folderVO: FolderVOData?
    var shareVOS: [ShareVOData]? {
        if let recordVO = recordVO {
            return recordVO.shareVOS
        } else {
            return folderVO?.shareVOS
        }
    }
    var pendingShareVOs: [MinArchiveVO] {
        fileViewModel.minArchiveVOS.filter({
            let status = ArchiveVOData.Status(rawValue: $0.shareStatus)
            return status == .pending
        })
    }
    var acceptedShareVOs: [MinArchiveVO] {
        fileViewModel.minArchiveVOS.filter({
            let status = ArchiveVOData.Status(rawValue: $0.shareStatus)
            return status != .pending
        })
    }
    
    var downloader: Downloader?
    
    let shareManagementRepository: ShareManagementRepository
    
    init(fileViewModel: FileModel!, shareManagementRepository: ShareManagementRepository = ShareManagementRepository(), downloader: Downloader? = DownloadManagerGCD()) {
        self.fileViewModel = fileViewModel
        self.shareManagementRepository = shareManagementRepository
        self.downloader = downloader
    }
    
    func getRecord(then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: fileViewModel.type,
            folderLinkId: fileViewModel.folderLinkId,
            parentFolderLinkId: fileViewModel.parentFolderLinkId
        )
        
        downloader?.getRecord(downloadInfo) { (record, error) in
            self.recordVO = record?.recordVO
            
            handler(record)
        }
    }
    
    func getFolder(then handler: @escaping (FolderVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: fileViewModel.type,
            folderLinkId: fileViewModel.folderLinkId,
            parentFolderLinkId: fileViewModel.parentFolderLinkId
        )
        
        downloader?.getFolder(downloadInfo) { (folder, error) in
            self.folderVO = folder?.folderVO
            
            handler(folder)
        }
    }
    
    func getShareLink(option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        shareManagementRepository.getShareLink(file: fileViewModel, option: option) { result, error in
            if result != nil {
                self.shareVO = result
                handler(self.shareVO, nil)
                
                if option == .create {
                    NotificationCenter.default.post(name: Self.didCreateShareLinkNotifName, object: self, userInfo: nil)
                }
            } else {
                handler(nil, error)
            }
        }
    }
    
    func revokeLink(then handler: @escaping ServerResponse) {
        shareManagementRepository.revokeLink(shareVO: shareVO) { result in
            if result == .success {
                NotificationCenter.default.post(name: Self.didRevokeShareLinkNotifName, object: self, userInfo: nil)
            }
            handler(result)
        }
    }
    
    func updateLink(model: ManageLinkData, then handler: @escaping ShareLinkResponse) {
        shareManagementRepository.updateLink(model: model, shareVO: shareVO) { result, error in
            if result != nil {
                self.processShareLinkUpdateModel(result)
            }
            handler(result, error)
        }
    }
    
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus) -> Void) {
        shareManagementRepository.approveButtonAction(minArchiveVO: minArchiveVO, accessRole: accessRole) { requestStatus, shareVO in
            if requestStatus == .success {
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == minArchiveVO.archiveID }) {
                    self.fileViewModel.minArchiveVOS[idx].accessRole = shareVO?.accessRole
                    self.fileViewModel.minArchiveVOS[idx].shareStatus = shareVO?.status ?? ""
                }
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
            }
            handler(requestStatus)
        }
    }
        
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus) -> Void) {
        shareManagementRepository.approveButtonAction(shareVO: shareVO, accessRole: accessRole) { requestStatus, shareVO in
            if requestStatus == .success {
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == shareVO?.archiveID }) {
                    self.fileViewModel.minArchiveVOS[idx].accessRole = shareVO?.accessRole
                    self.fileViewModel.minArchiveVOS[idx].shareStatus = shareVO?.status ?? ""
                }
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
            }
            handler(requestStatus)
        }
    }

    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void) {
        shareManagementRepository.denyButtonAction(minArchiveVO: minArchiveVO) { result in
            if result == .success {
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == minArchiveVO.archiveID }) {
                    self.fileViewModel.minArchiveVOS.remove(at: idx)
                }
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
            }
            handler(result)
        }
    }
    
    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        guard let archiveId = shareVO.archiveID else { return }
        
        shareManagementRepository.denyButtonAction(shareVO: shareVO) { result in
            if result == .success {
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == archiveId }) {
                    self.fileViewModel.minArchiveVOS.remove(at: idx)
                }
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
            }
            handler(result)
        }
    }

    fileprivate func processShareLinkUpdateModel(_ model: SharebyURLVOData?) {
        shareVO?.maxUses = model?.maxUses
        shareVO?.previewToggle = model?.previewToggle
        shareVO?.autoApproveToggle = model?.autoApproveToggle
        shareVO?.expiresDT = model?.expiresDT
        shareVO?.defaultAccessRole = model?.defaultAccessRole
    }
    
    func getAccountName() -> String? {
        let accountName: String? = AuthenticationManager.shared.session?.account.fullName
        return accountName
    }
    
    func updateLinkWithChangedField(previewToggle: Int? = nil, autoApproveToggle: Int? = nil, expiresDT: String? = nil, maxUses: Int? = nil, defaultAccessRole: AccessRole? = nil, then handler: @escaping ShareLinkResponse) {
        var expiresDate: String?
        if expiresDT == "clear" {
            expiresDate = nil
        } else {
            expiresDate = expiresDT != nil ? expiresDT : shareVO?.expiresDT
        }
        
        let manageLinkData = ManageLinkData(
            previewToggle: previewToggle != nil ? previewToggle : shareVO?.previewToggle,
            autoApproveToggle: autoApproveToggle != nil ? autoApproveToggle : shareVO?.autoApproveToggle,
            expiresDT: expiresDate,
            maxUses: maxUses != nil ? maxUses : shareVO?.maxUses,
            defaultAccessRole: defaultAccessRole
        )
        
        updateLink(model: manageLinkData, then: { shareVO, error in
            NotificationCenter.default.post(name: Self.didUpdateShareLinkRoleNotifName, object: self, userInfo: nil)
            handler(shareVO, error)
        })
    }
    
    func trackCopyLink() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.copyShareLink,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
