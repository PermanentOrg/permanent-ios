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
    
    override func shouldPerformAction(forSection section: Int) -> Bool {
        return section == FileListType.synced.rawValue && !currentFolderIsRoot
    }
    
    override func title(forSection section: Int) -> String {
        switch section {
        case FileListType.downloading.rawValue: return .downloads
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return currentFolderIsRoot ? "" : activeSortOption.title
        default: return "" // We cannot have more than 3 sections.
        }
    }
    
    func getShares(then handler: @escaping ServerResponse) {
        viewModels.removeAll()
        sharedByMeViewModels.removeAll()
        sharedWithMeViewModels.removeAll()
        
        let apiOperation = APIOperation(ShareEndpoint.getShares)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json(let response, _):
                    guard let model: APIResults<ArchiveVO> = JSONHelper.decoding( from: response, with: APIResults<ArchiveVO>.decoder)
                    else {
                        return handler(.error(message: .errorMessage))
                    }
                    
                    
                    let currentArchive: ArchiveVOData? = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
                    let currentArchiveId: Int? = currentArchive?.archiveID
                    
                    model.results.first?.data?.forEach { archive in
                        let itemVOS = archive.archiveVO?.itemVOS
                        
                        let archivePermissionsSet = Set(self.archivePermissions)
                        
                        itemVOS?.forEach {
                            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
                            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
                            
                            let sharedFileVM = FileViewModel(model: $0, archiveThumbnailURL: archive.archiveVO?.thumbURL200, permissions: permissionsIntersection)
                            
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
    
}
