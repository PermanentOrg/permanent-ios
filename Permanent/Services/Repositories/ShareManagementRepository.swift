//
//  ShareManagementRepository.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.11.2022.
//

import Foundation

class ShareManagementRepository {
    let remoteDataSource: ShareManagementRemoteDataSourceInterface
    
    init(remoteDataSource: ShareManagementRemoteDataSourceInterface = ShareManagementRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        remoteDataSource.getShareLink(file: file, option: option) { result, error in
            completion(result,error)
        }
    }
    
    func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse) {
        remoteDataSource.revokeLink(shareVO: shareVO) { result in
            handler(result)
        }
    }
    
    func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse) {
        remoteDataSource.updateLink(model: model, shareVO: shareVO) { result, share in
            handler(result, share)
        }
        
    }
    
    func approveButtonAction(minArchiveVO: MinArchiveVO, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
        remoteDataSource.approveButtonAction(minArchiveVO: minArchiveVO, accessRole: accessRole) { requestStatus, shareVOData in
            handler(requestStatus, shareVOData)
        }
    }
    
    func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
        remoteDataSource.approveButtonAction(shareVO: shareVO, accessRole: accessRole) { requestStatus, shareVO in
            handler(requestStatus, shareVO)
        }
    }
    
    func denyButtonAction(minArchiveVO: MinArchiveVO, then handler: @escaping (RequestStatus) -> Void) {
        remoteDataSource.denyButtonAction(minArchiveVO: minArchiveVO) { result in
            handler(result)
        }
    }
    
    func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        remoteDataSource.denyButtonAction(shareVO: shareVO) { result in
            handler(result)
        }
    }
    
    func getShareLinkV2(shareLinkId: String, then completion: @escaping ShareLinkV2Handler) {
        remoteDataSource.getShareLinkV2(shareLinkId: shareLinkId) { result, error in
            completion(result, error)
        }
    }
    
    func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        remoteDataSource.getShareLinkV2ByToken(token: token) { result, error in
            completion(result, error)
        }
    }
    
    func createShareLinkV2(file: FileModel, then completion: @escaping ShareLinkV2Handler) {
        remoteDataSource.createShareLinkV2(file: file) { result, error in
            completion(result, error)
        }
    }
    
    func updateShareLinkV2(
        shareLinkId: String,
        permissionsLevel: String? = nil,
        accessRestrictions: String? = nil,
        maxUses: Int? = nil,
        expirationTimestamp: String? = nil,
        then completion: @escaping ShareLinkV2Handler
    ) {
        remoteDataSource.updateShareLinkV2(
            shareLinkId: shareLinkId,
            permissionsLevel: permissionsLevel,
            accessRestrictions: accessRestrictions,
            maxUses: maxUses,
            expirationTimestamp: expirationTimestamp
        ) { result, error in
            completion(result, error)
        }
    }
    
    func deleteShareLinkV2(shareLinkId: String, then completion: @escaping (RequestStatus) -> Void) {
        remoteDataSource.deleteShareLinkV2(shareLinkId: shareLinkId) { result in
            completion(result)
        }
    }
}
