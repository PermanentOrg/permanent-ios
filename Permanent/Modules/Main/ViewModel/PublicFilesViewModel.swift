//
//  PublicFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 11.01.2022.
//

import Foundation

class PublicFilesViewModel: MyFilesViewModel {
    // Public Files reuses the inherited MyFilesViewModel V2 root discovery (VSP-1787 follow-up):
    // it lands in the archive's PUBLIC root via GET /api/v2/archives → rootFolderId → the
    // public-root child → /children, gated by useStelaNavigation, with V1 getPublicRoot as the
    // automatic failsafe. Same owner workspace, archive-level permissions apply.

    override var rootFolderName: String {
        return "Public Files".localized()
    }

    // Land in the archive's public root instead of My Files; the rest of getRoot is inherited.
    override var rootSectionType: FileType { .publicRootFolder }
    override var rootSectionFallbackDisplayName: String { "Public" }

    /// V1 failsafe for Public Files root discovery — the legacy getPublicRoot bootstrap,
    /// reached only when the V2 public-root resolution fails. Unlike the V2 path it does NOT
    /// seed `v2NavigationTarget`, so it lists the root via V1 navigateMin, preserving today's
    /// behavior.
    override func performV1GetRoot(then handler: @escaping ServerResponse) {
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
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
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
    
    override func trackOpenFiles(action: AccountEventAction) {
        super.trackOpenFiles(action: AccountEventAction.openPublicWorkspace)
    }
}
