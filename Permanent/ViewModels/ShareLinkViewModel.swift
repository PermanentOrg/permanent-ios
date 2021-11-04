//
//  ShareLinkViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

typealias ShareLinkResponse = (SharebyURLVOData?, String?) -> Void

class ShareLinkViewModel: NSObject, ViewModelInterface {
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
    
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus) -> Void) {
        var newShareVO = shareVO
        newShareVO.accessRole = AccessRole.apiRoleForValue(accessRole.groupName)
        let acceptShareRequestOperation = APIOperation(AccountEndpoint.updateShareRequest(shareVO: newShareVO))
        
        acceptShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                handler(.success)
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
              let archiveId = shareVO.archiveID else {
            handler(RequestStatus.error(message: nil))
            return
        }
        let shareId = shareVO.shareID ?? 0
        
        let denyShareRequestOperation = APIOperation(AccountEndpoint.deleteShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId))
        
        denyShareRequestOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                handler(.success)
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
}
