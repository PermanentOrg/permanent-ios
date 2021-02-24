//
//  SharedFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.02.2021.
//

import Foundation

class SharedFilesViewModel: FilesViewModel {
    
    override var currentFolderIsRoot: Bool { navigationStack.count == 0 }
    
    var shareListType: ShareListType = .sharedByMe {
        didSet {
            viewModels = shareListType == .sharedByMe ? sharedByMeViewModels : sharedWithMeViewModels
            navigationStack.removeAll()
        }
    }
    
    var sharedByMeViewModels: [FileViewModel] = []
    var sharedWithMeViewModels: [FileViewModel] = []
    
    func getShares(then handler: @escaping ServerResponse) {
        viewModels.removeAll()
        sharedByMeViewModels.removeAll()
        sharedWithMeViewModels.removeAll()
        
        let apiOperation = APIOperation(ShareEndpoint.getShares)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding( from: response, with: APIResults<ArchiveVO>.decoder)
                else {
                    return handler(.error(message: .errorMessage))
                }
                
                self.csrf = model.csrf
                
                let currentArchiveId: Int? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveIdStorageKey)
                
                model.results.first?.data?.forEach { archive in
                    let itemVOS = archive.archiveVO?.itemVOS
                    
                    itemVOS?.forEach {
                        let sharedFileVM = FileViewModel(model: $0, archiveThumbnailURL: archive.archiveVO?.thumbURL200)
                        
                        if $0.archiveID == currentArchiveId {
                            self.sharedByMeViewModels.append(sharedFileVM)
                        } else {
                            self.sharedWithMeViewModels.append(sharedFileVM)
                        }
                    }
                    
                    self.viewModels = self.shareListType == .sharedByMe ? self.sharedByMeViewModels : self.sharedWithMeViewModels
                }
                
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
}
