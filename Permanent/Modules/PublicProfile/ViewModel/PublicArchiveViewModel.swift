//
//  PublicArchiveViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.12.2021.
//

import Foundation

class PublicArchiveViewModel: FilesViewModel {
    private var _currentArchive: ArchiveVOData?
    override var currentArchive: ArchiveVOData? {
        get {
            return _currentArchive
        }
        
        set {
            _currentArchive = newValue
        }
    }
    
    /// Read-only, pinned at the archive level so every listing path agrees — otherwise
    /// capabilities depend on which backend served the listing. Governs own-archive browsing.
    override var archivePermissions: [Permission] { [.read] }
    override var archiveAccessRole: AccessRole { .viewer }

    override var currentFolderIsRoot: Bool { navigationStack.count == 1 }

    override var numberOfSections: Int {
        1
    }
    
    override func numberOfRowsInSection(_ section: Int) -> Int {
        return syncedViewModels.count
    }
    
    func heightForSection(_ section: Int) -> Double {
        0
    }
    
    override func fileForRowAt(indexPath: IndexPath) -> FileModel {
        switch indexPath.section {
        case 0:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func getRoot(then handler: @escaping ServerResponse) {
        // `currentArchive` and `archiveNbr` are both optional, and this screen can be entered by deep
        // link — so surface the same error the other failure branches do rather than force-unwrap.
        guard let archiveNbr = currentArchive?.archiveNbr else {
            handler(.error(message: .errorMessage))
            return
        }

        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: archiveNbr))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, handler)
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    /// Internal (not private) so the V1 → V2 root handoff below is unit-testable without
    /// standing up the network.
    func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }

        // Stela can't discover a foreign archive's root, so V1 stays the bootstrap and seeds the public
        // root as the V2 target. The `folderId > 0` gate means this can only add an attempt.
        v2NavigationTarget = FileModel(model: folderVO)

        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
    
    func publicURL(forFile file: FileModel) -> URL? {
        guard let currentArchive = currentArchive, let currentFolder = currentFolder else { return nil }
        
        let baseURLString = APIEnvironment.defaultEnv.publicURL
        let url: URL
        if file.type.isFolder {
            url = URL(string: "\(baseURLString)/archive/\(currentArchive.archiveNbr!)/\(file.archiveNo)/\(file.folderLinkId)")!
        } else {
            url = URL(string: "\(baseURLString)/archive/\(currentArchive.archiveNbr!)/\(currentFolder.archiveNo)/\(currentFolder.folderLinkId)/record/\(file.archiveNo)")!
        }
        
        return url
    }
}
