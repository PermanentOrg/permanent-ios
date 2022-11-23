//
//  ShareManagementRemoteDataSourceInterface.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.11.2022.
//

import Foundation

protocol ShareManagementRemoteDataSourceInterface {
    func getShareLink(file: FileViewModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse)
    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse)
    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse)
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> Void)
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> Void)
    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void)
    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void)
}

class ShareManagementRemoteDataSource: ShareManagementRemoteDataSourceInterface {
    func getShareLink(file: FileViewModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        let endpoint = option.endpoint(for: file)
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
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse) {
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
    
    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse) {
        guard let sharePayload = prepareShareLinkUpdatePayload(forData: model, shareVO: shareVO) else {
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
                handler(updatedModel, nil)
            
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
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
                    handler(.error(message: .errorMessage), nil)
                    return
                }
                
                if model.isSuccessful {
                    handler(.success, model.results.first?.data?.first?.shareVO)
                } else {
                    if model.results[0].message[0] == "warning.share.no_share_self" {
                        handler(.error(message: "You cannot share an item with yourself".localized()), nil)
                    } else {
                        handler(.error(message: .errorMessage), nil)
                    }
                }
                return
                
            case .error:
                handler(.error(message: .errorMessage), nil)
                return
                
            default:
                break
            }
        }
    }
    
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
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
                    handler(.error(message: .errorMessage), nil)
                    return
                }
                
                if model.isSuccessful {
                    handler(.success, model.results.first?.data?.first?.shareVO)
                } else {
                    if model.results[0].message[0] == "warning.share.no_share_self" {
                        handler(.error(message: "You cannot share an item with yourself".localized()), nil)
                    } else {
                        handler(.error(message: .errorMessage), nil)
                    }
                }
                return
                
            case .error:
                handler(.error(message: .errorMessage), nil)
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
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                break
            }
        }
    }
    
    private func prepareShareLinkUpdatePayload(forData data: ManageLinkData, shareVO: SharebyURLVOData?) -> SharebyURLVOData? {
        var payloadVO = shareVO
        payloadVO?.maxUses = data.maxUses
        payloadVO?.previewToggle = data.previewToggle
        payloadVO?.autoApproveToggle = data.autoApproveToggle
        payloadVO?.expiresDT = data.expiresDT
        
        return payloadVO
    }
}
