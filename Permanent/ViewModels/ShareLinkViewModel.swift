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
    func approveButtonAction(then handler: @escaping (RequestStatus) -> Void)
    func denyButtonAction(then handler: @escaping (RequestStatus) -> Void)
}

class ShareLinkViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var fileViewModel: FileViewModel!
    var shareVO: SharebyURLVOData?
    
    var shareListType: ShareListType = .sharedByMe
    
    var sharedByMeViewModels: [SharedFileViewModel] = []
    var sharedWithMeViewModels: [SharedFileViewModel] = []
    
    weak var delegate: ShareLinkViewModelDelegate?
    
    private lazy var downloader: Downloader = DownloadManagerGCD(csrf: csrf)
    
    var items: [SharedFileViewModel] {
        switch shareListType {
        case .sharedByMe: return sharedByMeViewModels
        case .sharedWithMe: return sharedWithMeViewModels
        }
    }
    
    func changeStatus(forFile file: FileDownloadInfo, status: FileStatus) {
//        guard
//            let item = items.first(where: { $0 == file} ) else {
//            return
//        }
        
        switch shareListType {
        case .sharedByMe:
            sharedByMeViewModels = sharedByMeViewModels.map {
                var mutableVM = $0
                
                if mutableVM.folderLinkId == file.folderLinkId {
                    mutableVM.status = status
                }
                
                return mutableVM
            }
            
        case .sharedWithMe:
            sharedWithMeViewModels = sharedWithMeViewModels.map {
                var mutableVM = $0
                
                if mutableVM.folderLinkId == file.folderLinkId {
                    mutableVM.status = status
                }
                
                return mutableVM
            }
        }
    }
}

extension ShareLinkViewModel: ShareLinkViewModelDelegate {
    func cancelDownload() {
        downloader.cancelDownload()
    }
    
    
    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?)
    {
        downloader.download(file,
                            onDownloadStart: onDownloadStart,
                            onFileDownloaded: onFileDownloaded,
                            progressHandler: progressHandler,
                            completion: nil)
    }
    
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
        
        let apiOperation = APIOperation(ShareEndpoint.revokeLink(link: shareVO, csrf: csrf))
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
        
        let apiOperation = APIOperation(ShareEndpoint.updateShareLink(link: sharePayload, csrf: csrf))
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
    func approveButtonAction(then handler: @escaping (RequestStatus) -> Void) {
        
        let acceptShareRequestOperation = APIOperation(AccountEndpoint.updateShareRequest(shareId: self.fileViewModel.minArchiveVOS.first!.shareId, folderLinkId: self.fileViewModel.folderLinkId, archiveId: self.fileViewModel.minArchiveVOS.first!.archiveID, csrf: self.csrf))
        
    
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
    
    func denyButtonAction(then handler: @escaping (RequestStatus) -> Void) {
        let denyShareRequestOperation = APIOperation(AccountEndpoint.deleteShareRequest(shareId: self.fileViewModel.minArchiveVOS.first!.shareId, folderLinkId: self.fileViewModel.folderLinkId, archiveId: self.fileViewModel.minArchiveVOS.first!.archiveID, csrf: self.csrf))
        
    
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
