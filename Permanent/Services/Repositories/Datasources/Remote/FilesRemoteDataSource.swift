//
//  FilesRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 10.10.2022.
//

import Foundation

protocol FilesRemoteDataSourceInterface {
    var currentArchive: ArchiveVOData? { get }
    var archivePermissions: [Permission] { get }
    
    func folderContent(archiveNo: String, folderLinkId: Int, byMe: Bool, completion: @escaping (([FileModel], Error?) -> Void))
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileModel?, Error?) -> Void))
    func getPrivateRoot(completion: @escaping ((FileModel?, Error?) -> Void))
    func getPublicRoot(completion: @escaping ((FileModel?, Error?) -> Void))
    func getSharedRoot(completion: @escaping ((FileModel?, Error?) -> Void))
}

class FilesRemoteDataSource: FilesRemoteDataSourceInterface {
    var currentArchive: ArchiveVOData? {
        return PermSession.currentSession?.selectedArchive
    }
    var archivePermissions: [Permission] {
        return currentArchive?.permissions() ?? [.read]
    }
    
    func folderContent(archiveNo: String, folderLinkId: Int, byMe: Bool = false, completion: @escaping (([FileModel], Error?) -> Void)) {
        if archiveNo == "archiveNo.Shared.Files" {
            getSharedRootContent(byMe: byMe, completion: completion)
        } else {
            let params: NavigateMinParams = NavigateMinParams(archiveNo, folderLinkId, nil)
            
            navigateMin(params: params, then: completion)
        }
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileModel?, Error?) -> Void)) {
        let newFolderParams = NewFolderParams(name, folderLinkId)
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: newFolderParams))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    completion(nil, APIError.parseError)
                    return
                }

                let folder = FileModel(model: folderVO, permissions: [], accessRole: .viewer)
                completion(folder, nil)

            case .error(let error, _):
                completion(nil, error)

            default:
                break
            }
        }
    }
    
    func getPrivateRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    completion(nil, APIError.parseError)
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetPrivateRootSuccess(model, completion)
                } else {
                    completion(nil, APIError.parseError)
                }
                
            case .error(let error, _):
                completion(nil, error)
                
            default:
                break
            }
        }
    }
    
    func getSharedRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        let folder = FileModel(name: "Shared Files", recordId: 0, folderLinkId: 0, archiveNbr: "archiveNo.Shared.Files", type: "", permissions: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            completion(folder, nil)
        })
    }
    
    func getSharedByMeRootContent(completion: @escaping (([FileModel], Error?) -> Void)) {
        getSharedRootContent(byMe: true, completion: completion)
    }
    
    func getSharedWithMeRootContent(completion: @escaping (([FileModel], Error?) -> Void)) {
        getSharedRootContent(byMe: false, completion: completion)
    }
    
    private func getSharedRootContent(byMe: Bool, completion: @escaping (([FileModel], Error?) -> Void)) {
        let apiOperation = APIOperation(ShareEndpoint.getShares)

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<ArchiveVO> = JSONHelper.decoding( from: response, with: APIResults<ArchiveVO>.decoder)
                else {
                    return completion([], nil)
                }

                var fileViewModels: [FileModel] = []

                let currentArchiveId: Int? = self.currentArchive?.archiveID

                model.results.first?.data?.forEach { archive in
                    let itemVOS = archive.archiveVO?.itemVOS

                    let archivePermissionsSet = Set(self.archivePermissions)

                    itemVOS?.forEach {
                        let accessRole = AccessRole.roleForValue($0.accessRole)
                        let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
                        let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))

                        let sharedByArchive = $0.archiveID == currentArchiveId ? nil : archive.archiveVO
                        let sharedFileVM = FileModel(model: $0, archiveThumbnailURL: archive.archiveVO?.thumbURL200, sharedByArchive: sharedByArchive, permissions: permissionsIntersection, accessRole: accessRole)
                        let append: Bool = byMe ? $0.archiveID == currentArchiveId : $0.archiveID != currentArchiveId
                        if append {
                            fileViewModels.append(sharedFileVM)
                        }
                    }
                }

                completion(fileViewModels, nil)

            case .error(let error, _):
                completion([], error)

            default:
                break
            }
        }
    }
    
    func getPublicRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    completion(nil, APIError.parseError)
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetPublicRootSuccess(model, completion)
                } else {
                    completion(nil, APIError.parseError)
                }
                
            case .error(let error, _):
                completion(nil, error)
                
            default:
                break
            }
        }
    }
    
    // MARK: - Private
    private func navigateMin(params: NavigateMinParams, then handler: @escaping (([FileModel], Error?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler([], APIError.parseError)
                    return
                }
                
                self.onNavigateMinSuccess(model, handler)
                
            case .error(let error, _):
                handler([], error)
                
            default:
                break
            }
        }
    }
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, sortOption: SortOption = .nameAscending, _ handler: @escaping (([FileModel], Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler([], APIError.clientError)
            return
        }
        
        let folderLinkIds: [Int] = childItems.compactMap { $0.folderLinkID }
        
        let params: GetLeanItemsParams = (archiveNo, sortOption, folderLinkIds, folderLinkId)
        getLeanItems(params: params, then: handler)
    }
    
    private func getLeanItems(params: GetLeanItemsParams, then handler: @escaping (([FileModel], Error?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.getLeanItems(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler([], APIError.parseError)
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetLeanItemsSuccess(model, handler)
                } else {
                    handler([], APIError.serverError)
                }
                
            case .error(let error, _):
                handler([], error)
                
            default:
                break
            }
        }
    }
    
    private func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping (([FileModel], Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler([], APIError.clientError)
            return
        }
        
        let archivePermissionsSet = Set(self.archivePermissions)
            
        var viewModels: [FileModel] = []
        childItems.forEach {
            let accessRole = AccessRole.roleForValue($0.accessRole)
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            let file = FileModel(model: $0, permissions: permissionsIntersection, accessRole: .viewer)
            viewModels.append(file)
        }
        
        handler(viewModels, nil)
    }
    
    private func onGetPrivateRootSuccess(_ model: GetRootResponse, _ handler: @escaping ((FileModel?, Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.type == Constants.API.FileType.typeFolderRootPrivate })
        else {
            handler(nil, APIError.clientError)
            return
        }
        
        let folder = FileModel(model: myFilesFolder)
        handler(folder, nil)
    }
    
    private func onGetPublicRootSuccess(_ model: GetRootResponse, _ handler: @escaping ((FileModel?, Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.type == Constants.API.FileType.typeFolderRootPublic })
        else {
            handler(nil, APIError.clientError)
            return
        }
        
        let folder = FileModel(model: myFilesFolder)
        handler(folder, nil)
    }
}

class FilesRemoteMockDataSource: FilesRemoteDataSourceInterface {
    var currentArchive: ArchiveVOData?
    var archivePermissions: [Permission] {
        return currentArchive?.permissions() ?? [.read]
    }
    
    var folderContentMockFiles: [FileModel] = []
    var newFolderMock: FileModel?
    var privateRootMock: FileModel?
    
    func folderContent(archiveNo: String, folderLinkId: Int, byMe: Bool, completion: @escaping (([FileModel], Error?) -> Void)) {
        completion(folderContentMockFiles, nil)
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileModel?, Error?) -> Void)) {
        completion(newFolderMock, nil)
    }
    
    func getPrivateRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        completion(privateRootMock, nil)
    }
    
    func getPublicRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        completion(privateRootMock, nil)
    }
    
    func getSharedRoot(completion: @escaping ((FileModel?, Error?) -> Void)) {
        completion(privateRootMock, nil)
    }
}

