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
    
//    override var selectedFile: FileViewModel? {
//        get {
//            return AuthenticationManager.shared.session?.selectedFile
//        }
//
//        set {
//            AuthenticationManager.shared.session?.selectedFile = newValue
//        }
//    }
    
//    override var fileAction: FileAction {
//        get {
//            return AuthenticationManager.shared.session?.fileAction ?? .none
//        }
//
//        set {
//            AuthenticationManager.shared.session?.fileAction = newValue
//        }
//    }
    var localSelectedFile: FileViewModel?
    var localFileAction: FileAction = .none
    
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
                    
                    let currentArchive: ArchiveVOData? = AuthenticationManager.shared.session?.selectedArchive
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
    
    override func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems.compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let archivePermissionsSet = Set(self.archivePermissions)
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: folderVO.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            let file = FileViewModel(model: folderVO, permissions: permissionsIntersection)
            navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, activeSortOption, folderLinkIds, folderLinkId)
        getLeanItems(params: params, then: handler)
    }
    
    override func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        viewModels.removeAll()
        
        let archivePermissionsSet = Set(self.archivePermissions)
        childItems.forEach {
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            let file = FileViewModel(model: $0, permissions: permissionsIntersection)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }
}
