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
    
    /// Enable Stela V2 folder drill-in for the Public Gallery (same switch the other file
    /// screens use), with the V1 two-step navigation kept as the automatic failsafe. Root
    /// DISCOVERY stays on V1 `getPublicRoot`: V2 `/archives` is scoped to the caller's
    /// `callerMembershipRole`, so a foreign archive is never listed and the section-root
    /// resolver `MyFilesViewModel` uses cannot resolve one. Verified 2026-07-28 against
    /// staging: `/api/v2/folders/{id}/children` serves a foreign archive's public tree on
    /// bearer auth (in fact with no auth at all), so the listing itself needs no membership.
    override var usesStelaNavigation: Bool { FeatureFlags.useStelaNavigation }

    /// The public browser is READ-ONLY, pinned at the archive level so every listing path
    /// agrees — V2 `/children` (via the base `v2ChildContext`), the V1 `getLeanItems`
    /// failsafe, and the `navigateMin` folder push all read these two properties.
    ///
    /// Pinning only the V2 leg would make the user's capabilities depend on which backend
    /// happened to serve the listing: `navigateV2` falls back to V1 on any error, so the
    /// same photo in the same folder would offer "Publish on the web" / "Share to Permanent"
    /// and editable metadata after a transient V2 failure and not before. Those controls are
    /// gated on the per-item `permissions` this stamps (`FilePreviewViewController` /
    /// `FileDetailsViewController` share menus, and `FilePreviewViewModel.isEditable`).
    ///
    /// For a FOREIGN archive this changes nothing — `accessRole` comes back null, which
    /// `AccessRole.roleForValue` already maps to `.viewer` and `ArchiveVOData.permissions()`
    /// to `[.read]`. It narrows exactly one case: browsing your OWN archive through the
    /// gallery, where the archive role is owner. That narrowing is deliberate — this screen
    /// has no write UI of its own, so those affordances only ever arrived incidentally
    /// through the shared preview component.
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
        // `currentArchive` is assigned from the host VC's implicitly-unwrapped `archiveData`,
        // and `archiveNbr` is optional on the VO — so this pair was two force-unwraps away
        // from a crash on a screen that can also be entered by deeplink. Surface the same
        // error the other failure branches do instead (matches the VSP-1787 hardening of
        // `PublicFilesViewModel.getRoot`).
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

        // Stela has no root-discovery route for a foreign archive, so the V1 getPublicRoot
        // above stays as the bootstrap. When V2 is on, seed the navigation target with the
        // public root itself so navigateMin lists it via /folders/{id}/children. The
        // `folderId > 0` gate in navigateMin rejects a target the V1 payload didn't carry
        // an id for, which falls through to V1 — so this can only ever add a V2 attempt.
        if usesStelaNavigation {
            v2NavigationTarget = FileModel(model: folderVO)
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
}
