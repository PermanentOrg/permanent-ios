//  
//  SharePreviewViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

class SharePreviewViewModel {
    
    // MARK: - Delegates
        
    weak var viewDelegate: SharePreviewViewModelViewDelegate?
    
    // MARK: - Properties
    
    fileprivate var files: [File] = []
    
    var urlToken: String!

    var shareDetails: ShareDetails?
    
    var isBusy: Bool = false {
        didSet {
            viewDelegate?.updateSpinner(isLoading: isBusy)
        }
    }

    // MARK: - Events
    
    func start() {
        fetchSharedItems(urlToken: urlToken)
    }
    
    func performAction() {
        
        switch self.shareDetails?.status {
        case .accepted:
            viewDelegate?.viewInArchive()
            
        case .needsApproval:
            requestShareAccess(urlToken: urlToken)
            
        default:
            break
        }
        
    }
    
    
    // MARK: - Network
    
    func fetchSharedItems(urlToken: String) {
        
        isBusy = true
        
        let apiOperation = APIOperation(ShareEndpoint.checkLink(token: urlToken))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.isBusy = false
            
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),

                    model.isSuccessful,
                    let shareByURL = model.results.first?.data?.first?.shareByURLVO else {
                    
                    self.viewDelegate?.updateScreen(
                        status: .error(message: .errorMessage),
                        shareDetails: nil)
                    return
                }
                
                self.onFetchSharedItemsSuccess(shareByURL)
                
               
            case .error(let error, _):
                self.viewDelegate?.updateScreen(
                    status: .error(message: error?.localizedDescription),
                    shareDetails: nil)
                
            default:
                return
            }
        }
        
    }
    
    func requestShareAccess(urlToken: String) {
        isBusy = true
        
        let apiOperation = APIOperation(ShareEndpoint.requestShareAccess(token: urlToken))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.isBusy = false
            
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    ),

                    model.isSuccessful,
                    let shareVO = model.results.first?.data?.first?.shareVO else {
                    
                    self.viewDelegate?.updateShareAccess(
                        status: .error(message: .errorMessage),
                        shareStatus: nil)
                    
                    return
                }

                let status = ShareStatus.status(forValue: shareVO.status)
                self.shareDetails?.status = status
            
                self.viewDelegate?.updateShareAccess(status: .success, shareStatus: status)
            
            break
               
            case .error(let error, _):
                self.viewDelegate?.updateShareAccess(
                    status: .error(message: error?.localizedDescription),
                    shareStatus: nil)
                
            default:
                return
            }
        }
        
    }
    
    
    
    fileprivate func onFetchSharedItemsSuccess(_ model: SharebyURLVOData) {
        
        if let folderData = model.folderData {
            if let files = extractSharedFiles(from: folderData) {
                self.files = files
            }
        } else if let recordData = model.recordData {
            if let file = extractSharedFile(from: recordData) {
                self.files = [file]
            }
        }
        
        let details = ShareDetailsVM(model: model)
        self.shareDetails = details
        viewDelegate?.updateScreen(status: .success, shareDetails: details)
        
        // Delete the saved token if it existed.
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
    }
    
    fileprivate func extractSharedFiles(from folder: FolderVOData) -> [File]? {
        return folder.childItemVOS?.compactMap { FileVM(folder: $0) }
    }
    
    fileprivate func extractSharedFile(from record: RecordVOData) -> File? {
        return FileVM(record: record)
    }
    
}

extension SharePreviewViewModel: SharePreviewViewModelDelegate {
    
    var numberOfItems: Int {
        return files.count
    }
    
    func itemFor(row: Int) -> File {
        return files[row]
    }
    
}
