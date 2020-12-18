//  
//  ShareLinkViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

typealias ShareLinkResponse = (SharebyURLVOData?, String?) -> Void

protocol ShareLinkViewModelDelegate: ViewModelDelegateInterface {
    func getShareLink(option: ShareLinkOption, then handler: @escaping ShareLinkResponse)
}

class ShareLinkViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var fileViewModel: FileViewModel!
    var shareVO: SharebyURLVOData?
    
    var shareListType: ShareListType = .sharedByMe
    
    var sharedByMeViewModels: [SharedFileViewModel] = []
    var sharedWithMeViewModels: [SharedFileViewModel] = []
    
    weak var delegate: ShareLinkViewModelDelegate?
    
    
    var items: [SharedFileViewModel] {
        switch shareListType {
        case.sharedByMe: return sharedByMeViewModels
        case .sharedWithMe: return sharedWithMeViewModels
        }
    }
     
}

extension ShareLinkViewModel: ShareLinkViewModelDelegate {
    func getShareLink(option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        let endpoint = option.endpoint(for: fileViewModel, and: csrf)
        let apiOperation = APIOperation(endpoint)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),
                    model.isSuccessful else {
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
        
        let apiOperation = APIOperation(ShareEndpoint.revokeLink(link: shareVO, csrf: csrf))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful else {
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
        
        let apiOperation = APIOperation(ShareEndpoint.updateShareLink(link: sharePayload, csrf: csrf))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),
                    model.isSuccessful else {
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
    
    func getShares(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(ShareEndpoint.getShares)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding(
                    from: response,
                    with: APIResults<ArchiveVO>.decoder
                ) else {
                    return handler(.error(message: .errorMessage))
                }
                
                let currentArchiveId: Int? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveIdStorageKey)
                
                model.results.first?.data?.forEach { archive in
                    let itemVOS = archive.archiveVO?.itemVOS
                    
                    itemVOS?.forEach {
                        let sharedFileVM = SharedFileViewModel(model: $0, thumbURL: archive.archiveVO?.thumbURL200)
                        
                        if $0.archiveID == currentArchiveId {
                            self.sharedByMeViewModels.append(sharedFileVM)
                        } else {
                            self.sharedWithMeViewModels.append(sharedFileVM)
                        }
                    }
                }
                
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func prepareShareLinkUpdatePayload(forData data: ManageLinkData) -> SharebyURLVOData? {
        var payloadVO = self.shareVO
        payloadVO?.maxUses = data.maxUses
        payloadVO?.previewToggle = data.previewToggle
        payloadVO?.autoApproveToggle = data.autoApproveToggle
        payloadVO?.expiresDT = data.expiresDT
        
        return payloadVO
    }
    
    fileprivate func processShareLinkUpdateModel(_ model: SharebyURLVOData?) {
        self.shareVO?.maxUses = model?.maxUses
        self.shareVO?.previewToggle = model?.previewToggle
        self.shareVO?.autoApproveToggle = model?.autoApproveToggle
        self.shareVO?.expiresDT = model?.expiresDT
    }
}
