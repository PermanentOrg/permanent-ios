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
                handler(model.results.first?.data?.first?.shareByURLVO, nil)
                
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
        if let defaultAccessRole = data.defaultAccessRole {
            payloadVO?.defaultAccessRole = defaultAccessRole.apiValue
        }
        
        return payloadVO
    }
}

class ShareManagementMockRemoteDataSource: ShareManagementRemoteDataSourceInterface {
    // Create SharebyURLVOData mock object
    func sharebyURLVODataMock() -> SharebyURLVOData {
        let json = "{\"Results\":[{\"data\":[{\"Shareby_urlVO\":{\"shareby_urlId\":919,\"folder_linkId\":111145,\"status\":\"status.generic.ok\",\"urlToken\":\"7e50e4fe99cc16892f3d0376df054b6ea56432e0ba9a563eebab08f70f34596b\",\"shareUrl\":\"https:\\/\\/staging.permanent.org\\/share\\/7e50e4fe99cc16892f3d0376df054b6ea56432e0ba9a563eebab08f70f34596b\",\"uses\":3,\"maxUses\":0,\"autoApproveToggle\":1,\"previewToggle\":1,\"defaultAccessRole\":\"access.role.curator\",\"expiresDT\":null,\"byAccountId\":1648,\"byArchiveId\":1858,\"createdDT\":\"2022-11-25T16:51:33\",\"updatedDT\":\"2022-11-30T12:40:19\",\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":null,\"AccountVO\":null,\"ShareVO\":null}}],\"message\":[\"Link exists\"],\"status\":true,\"resultDT\":\"2022-12-07T10:32:42\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}"
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<SharebyURLVO> = try! decoder.decode(APIResults<SharebyURLVO>.self, from: data)

        return model.results.first!.data!.first!.shareByURLVO!
    }

    func shareVODataMock() -> ShareVOData {
        let json = "{\"Results\":[{\"data\":[{\"ShareVO\":{\"shareId\":1874,\"folder_linkId\":111145,\"archiveId\":1850,\"accessRole\":\"access.role.curator\",\"type\":\"type.share.record\",\"status\":\"status.generic.ok\",\"requestToken\":\"633442b551a7f216c8fba68206dba953b9a1ca31e1d4ccea2b74d6ed9ca87ab5\",\"previewToggle\":null,\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":null,\"AccountVO\":null,\"createdDT\":\"2022-11-25T16:51:50\",\"updatedDT\":\"2022-12-07T10:35:34\"}}],\"message\":[\"New share created or existing share updated\"],\"status\":true,\"resultDT\":\"2022-12-07T10:35:34\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}"
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<ShareVO> = try! decoder.decode(APIResults<ShareVO>.self, from: data)

        return model.results.first!.data!.first!.shareVO
    }

    private func prepareShareLinkUpdatePayload(forData data: ManageLinkData, shareVO: SharebyURLVOData?) -> SharebyURLVOData? {
        return nil
    }

    func getShareLink(file: FileViewModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        handler(sharebyURLVODataMock(), nil)
    }

    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse) {
        handler(.success)
    }

    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse) {
        handler(sharebyURLVODataMock(), nil)
    }

    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> ()) {
        handler(.success, shareVODataMock())
    }

    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> ()) {
        handler(.success, shareVODataMock())
    }

    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void) {
        handler(.success)
    }

    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        handler(.success)
    }
}