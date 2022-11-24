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
    
    var fileViewModel: FileViewModel!
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
    var pendingShareVOs: [ShareVOData]? {
        shareVOS?.filter({
            let status = ArchiveVOData.Status(rawValue: $0.status ?? "")
            return status == .pending
        })
    }
    var acceptedShareVOs: [ShareVOData]? {
        shareVOS?.filter({
            let status = ArchiveVOData.Status(rawValue: $0.status ?? "")
            return status != .pending
        })
    }
    
    var downloader: DownloadManagerGCD?
    
    func getRecord(then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: fileViewModel.type,
            folderLinkId: fileViewModel.folderLinkId,
            parentFolderLinkId: fileViewModel.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
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
        
        downloader = DownloadManagerGCD()
        downloader?.getFolder(downloadInfo) { (folder, error) in
            self.folderVO = folder?.folderVO
            
            handler(folder)
        }
    }
    
    func getShareLink(option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        let endpoint = option.endpoint(for: fileViewModel)
        let apiOperation = APIOperation(endpoint)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(nil, .errorMessage)
                    return
                }
            
                self.shareVO = model.results.first?.data?.first?.shareByURLVO
                handler(self.shareVO, nil)
                
                if option == .create {
                    NotificationCenter.default.post(name: Self.didCreateShareLinkNotifName, object: self, userInfo: nil)
                }
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    func revokeLink(then handler: @escaping ServerResponse) {
        guard let shareVO = shareVO else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let apiOperation = APIOperation(ShareEndpoint.revokeLink(link: shareVO))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                handler(.success)
                NotificationCenter.default.post(name: Self.didRevokeShareLinkNotifName, object: self, userInfo: nil)
            
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func updateLink(model: ManageLinkData, then handler: @escaping ShareLinkResponse) {
        guard let sharePayload = prepareShareLinkUpdatePayload(forData: model) else {
            handler(nil, .errorMessage)
            return
        }
        
        let apiOperation = APIOperation(ShareEndpoint.updateShareLink(link: sharePayload))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(nil, .errorMessage)
                    return
                }
                
                let updatedModel = model.results.first?.data?.first?.shareByURLVO
                self.processShareLinkUpdateModel(updatedModel)
                handler(self.shareVO, nil)
            
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus) -> Void) {
        var newShareVO = minArchiveVO
        newShareVO.accessRole = AccessRole.apiRoleForValue(accessRole.groupName)
        
        let acceptShareRequestOperation = APIOperation(AccountEndpoint.updateShareArchiveRequest(archiveVO: newShareVO))
        acceptShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    )
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful {
                    handler(.success)
                    if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == minArchiveVO.archiveID }) {
                        self.fileViewModel.minArchiveVOS[idx].accessRole = model.results.first?.data?.first?.shareVO.accessRole
                        self.fileViewModel.minArchiveVOS[idx].shareStatus = model.results.first?.data?.first?.shareVO.status ?? ""
                    }
                    NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
                } else {
                    if model.results[0].message[0] == "warning.share.no_share_self" {
                        handler(.error(message: "You cannot share an item with yourself".localized()))
                    } else {
                        handler(.error(message: .errorMessage))
                    }
                }
                
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                break
            }
        }
    }
        
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus) -> Void) {
        var newShareVO = shareVO
        newShareVO.accessRole = AccessRole.apiRoleForValue(accessRole.groupName)
        let acceptShareRequestOperation = APIOperation(AccountEndpoint.updateShareRequest(shareVO: newShareVO))
        
        acceptShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    )
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful {
                    handler(.success)
                    if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == newShareVO.archiveID }) {
                        self.fileViewModel.minArchiveVOS[idx].accessRole = model.results.first?.data?.first?.shareVO.accessRole
                        self.fileViewModel.minArchiveVOS[idx].shareStatus = model.results.first?.data?.first?.shareVO.status ?? ""
                    }
                    NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
                } else {
                    if model.results[0].message[0] == "warning.share.no_share_self" {
                        handler(.error(message: "You cannot share an item with yourself".localized()))
                    } else {
                        handler(.error(message: .errorMessage))
                    }
                }
                
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                break
            }
        }
    }

    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void) {
        guard let folderLinkId = minArchiveVO.folderLinkID else { return }
        
        let archiveId = minArchiveVO.archiveID
        let shareId = minArchiveVO.shareId
        
        let denyShareRequestOperation = APIOperation(AccountEndpoint.deleteShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId))
        
        denyShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                handler(.success)
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == archiveId }) {
                    self.fileViewModel.minArchiveVOS.remove(at: idx)
                }
                
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                break
            }
        }
    }
    
    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        guard let folderLinkId = shareVO.folderLinkID,
              let archiveId = shareVO.archiveID,
              let shareId = shareVO.shareID else { return }
        
        let denyShareRequestOperation = APIOperation(AccountEndpoint.deleteShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId))
        
        denyShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                handler(.success)
                if let idx = self.fileViewModel.minArchiveVOS.firstIndex(where: { $0.archiveID == archiveId }) {
                    self.fileViewModel.minArchiveVOS.remove(at: idx)
                }
                NotificationCenter.default.post(name: Self.didUpdateSharesNotifName, object: self, userInfo: nil)
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                break
            }
        }
    }
    
    func prepareShareLinkUpdatePayload(forData data: ManageLinkData) -> SharebyURLVOData? {
        var payloadVO = shareVO
        payloadVO?.maxUses = data.maxUses
        payloadVO?.previewToggle = data.previewToggle
        payloadVO?.autoApproveToggle = data.autoApproveToggle
        payloadVO?.expiresDT = data.expiresDT
        
        return payloadVO
    }
    
    fileprivate func processShareLinkUpdateModel(_ model: SharebyURLVOData?) {
        shareVO?.maxUses = model?.maxUses
        shareVO?.previewToggle = model?.previewToggle
        shareVO?.autoApproveToggle = model?.autoApproveToggle
        shareVO?.expiresDT = model?.expiresDT
    }
    
    func getAccountName() -> String? {
        let accountName: String? = AuthenticationManager.shared.session?.account.fullName
        return accountName
    }
    
    func updateLinkWithChangedField(previewToggle: Int? = nil, autoApproveToggle: Int? = nil, expiresDT: String? = nil, maxUses: Int? = nil, then handler: @escaping ShareLinkResponse) {
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
            maxUses: maxUses != nil ? maxUses : shareVO?.maxUses)
        
        
        updateLink(
            model: manageLinkData,
            then: { shareVO, error in
                handler(shareVO, error)
            }
        )
    }
}
