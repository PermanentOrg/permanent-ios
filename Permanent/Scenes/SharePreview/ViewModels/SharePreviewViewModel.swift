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
    
    var urlToken: String?
    
    func start() {
        
        guard let token = urlToken else { return }
        
        fetchSharedItems(urlToken: token)
        
    }
    
    // MARK: - Network
    
    func fetchSharedItems(urlToken: String) {
        
        let apiOperation = APIOperation(ShareEndpoint.checkLink(token: urlToken))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ),

                    model.isSuccessful,
                    let sss = model.results.first?.data?.first?.shareByURLVO else {
                    
                    self.viewDelegate?.updateScreen(
                        status: .error(message: .errorMessage),
                        shareDetails: nil)
                    return
                }
                
                self.onFetchSharedItemsSuccess(sss)
                
               
            case .error(let error, _):
                self.viewDelegate?.updateScreen(
                    status: .error(message: error?.localizedDescription),
                    shareDetails: nil)
                
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
        
        viewDelegate?.updateScreen(status: .success, shareDetails: details)
        
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
