//
//  ShareManagementRemoteDataSourceInterface.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.11.2022.
//

import Foundation

protocol ShareManagementRemoteDataSourceInterface {
    func getShareLink(file: FileModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse)
    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse)
    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse)
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> Void)
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> Void)
    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void)
    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void)
    func getShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler)
    func getShareLinkV2(shareLinkId: String, then handler: @escaping ShareLinkV2Handler)
    func createShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler)
    func updateShareLinkV2(
        shareLinkId: String,
        permissionsLevel: String?,
        accessRestrictions: String?,
        maxUses: Int?,
        expirationTimestamp: String?,
        then handler: @escaping ShareLinkV2Handler
    )
    func deleteShareLinkV2(shareLinkId: String, then handler: @escaping (RequestStatus) -> Void)
}

class ShareManagementRemoteDataSource: ShareManagementRemoteDataSourceInterface {
    func getShareLink(file: FileModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
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
    
    func getShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler) {
        // We need the shareLinkId to get V2 data, but this method signature expects a FileModel
        // This is a limitation of the current interface - ideally we'd have a separate method
        // that takes shareLinkId directly. For now, return nil to indicate V2 data not available
        // from this method signature.
        handler(nil, nil)
    }
    
    func getShareLinkV2(shareLinkId: String, then handler: @escaping ShareLinkV2Handler) {
        let apiOperation = APIOperation(ShareLinksV2Endpoint.getShareLink(shareLinkId: shareLinkId))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: ShareLinkV2Response = JSONHelper.decoding(
                        from: response,
                        with: ShareLinkV2Response.decoder
                    )
                else {
                    handler(nil, .errorMessage)
                    return
                }
                
                // Extract the first share link from the response
                if let firstShareLink = model.items?.first {
                    handler(firstShareLink, nil)
                } else {
                    handler(nil, "Share link not found")
                }

            case .error(let error, _):
                handler(nil, error?.localizedDescription)
            default:
                handler(nil, .errorMessage)
            }
        }
    }
    
    func createShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler) {
        let apiOperation = APIOperation(ShareLinksV2Endpoint.createShareLink(file: file))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: ShareLinkV2 = JSONHelper.decoding(
                        from: response,
                        with: ShareLinkV2.decoder
                    )
                else {
                    handler(nil, .errorMessage)
                    return
                }
                handler(model.data, nil)
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                handler(nil, .errorMessage)
            }
        }
    }
    
    func updateShareLinkV2(
        shareLinkId: String,
        permissionsLevel: String?,
        accessRestrictions: String?,
        maxUses: Int?,
        expirationTimestamp: String?,
        then handler: @escaping ShareLinkV2Handler
    ) {
        let apiOperation = APIOperation(ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: shareLinkId,
            permissionsLevel: permissionsLevel,
            accessRestrictions: accessRestrictions,
            maxUses: maxUses,
            expirationTimestamp: expirationTimestamp
        ))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: ShareLinkV2 = JSONHelper.decoding(
                        from: response,
                        with: ShareLinkV2.decoder
                    )
                else {
                    handler(nil, .errorMessage)
                    return
                }
                handler(model.data, nil)
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                handler(nil, .errorMessage)
            }
        }
    }
    
    func deleteShareLinkV2(shareLinkId: String, then handler: @escaping (RequestStatus) -> Void) {
        let apiOperation = APIOperation(ShareLinksV2Endpoint.deleteShareLink(shareLinkId: shareLinkId))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, let statusCode):
                // According to the API documentation, a 204 status code means success
                if let httpResponse = statusCode, httpResponse.statusCode == 204 {
                    handler(.success)
                } else {
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
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                handler(.error(message: .errorMessage))
            }
        }
    }
}

class ShareManagementMockRemoteDataSource: ShareManagementRemoteDataSourceInterface {
    var sharebyURLVODataMock: SharebyURLVOData!
    var shareVODataMock: ShareVOData!

    private func prepareShareLinkUpdatePayload(forData data: ManageLinkData, shareVO: SharebyURLVOData?) -> SharebyURLVOData? {
        return nil
    }

    func getShareLink(file: FileModel, option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        handler(sharebyURLVODataMock, nil)
    }

    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse) {
        handler(.success)
    }

    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse) {
        handler(sharebyURLVODataMock, nil)
    }

    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> ()) {
        handler(.success, shareVODataMock)
    }

    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole, then handler: @escaping (RequestStatus, ShareVOData?) -> ()) {
        handler(.success, shareVODataMock)
    }

    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void) {
        handler(.success)
    }

    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        handler(.success)
    }
    
    func getShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler) {
        // Mock implementation - create a sample V2 data
        let mockV2Data = ShareLinkV2Data(
            id: "mock-id",
            itemId: "mock-item-id", 
            itemType: "record",
            token: "mock-token-123",
            permissionsLevel: "viewer",
            accessRestrictions: "none",
            maxUses: nil,
            usesExpended: 0,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
        handler(mockV2Data, nil)
    }
    
    func getShareLinkV2(shareLinkId: String, then handler: @escaping ShareLinkV2Handler) {
        // Mock implementation - create a sample V2 data using the provided shareLinkId
        let mockV2Data = ShareLinkV2Data(
            id: shareLinkId,
            itemId: "mock-item-id", 
            itemType: "record",
            token: "mock-token-123",
            permissionsLevel: "viewer",
            accessRestrictions: "none",
            maxUses: nil,
            usesExpended: 0,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
        handler(mockV2Data, nil)
    }
    
    func createShareLinkV2(file: FileModel, then handler: @escaping ShareLinkV2Handler) {
        // Mock implementation - create a sample V2 data
        let mockV2Data = ShareLinkV2Data(
            id: "mock-id",
            itemId: "mock-item-id",
            itemType: "record", 
            token: "mock-token-123",
            permissionsLevel: "viewer",
            accessRestrictions: "none",
            maxUses: nil,
            usesExpended: 0,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
        handler(mockV2Data, nil)
    }
    
    func updateShareLinkV2(
        shareLinkId: String,
        permissionsLevel: String?,
        accessRestrictions: String?,
        maxUses: Int?,
        expirationTimestamp: String?,
        then handler: @escaping ShareLinkV2Handler
    ) {
        // Mock implementation - create updated V2 data
        let mockV2Data = ShareLinkV2Data(
            id: shareLinkId,
            itemId: "mock-item-id",
            itemType: "record",
            token: "mock-token-123",
            permissionsLevel: permissionsLevel ?? "viewer",
            accessRestrictions: accessRestrictions ?? "none",
            maxUses: maxUses,
            usesExpended: 0,
            expirationTimestamp: expirationTimestamp,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
        handler(mockV2Data, nil)
    }
    
    func deleteShareLinkV2(shareLinkId: String, then handler: @escaping (RequestStatus) -> Void) {
        // Mock successful deletion
        handler(.success)
    }
}
