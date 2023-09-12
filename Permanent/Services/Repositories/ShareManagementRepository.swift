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
}
