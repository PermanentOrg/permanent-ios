//
//  FilesRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 10.10.2022.
//

import Foundation

protocol FilesRemoteDataSourceInterface {
    func folderContent(archiveNo: String, folderLinkId: Int, completion: @escaping (([FileViewModel], Error?) -> Void))
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileViewModel?, Error?) -> Void))
    func getPrivateRoot(completion: @escaping ((FileViewModel?, Error?) -> Void))
}

class FilesRemoteDataSource: FilesRemoteDataSourceInterface {
    func folderContent(archiveNo: String, folderLinkId: Int, completion: @escaping (([FileViewModel], Error?) -> Void)) {
        let params: NavigateMinParams = NavigateMinParams(archiveNo, folderLinkId, nil)
        
        navigateMin(params: params, then: completion)
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileViewModel?, Error?) -> Void)) {
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

                let folder = FileViewModel(model: folderVO, permissions: [], accessRole: .viewer)
                completion(folder, nil)

            case .error(let error, _):
                completion(nil, error)

            default:
                break
            }
        }
    }
    
    func getPrivateRoot(completion: @escaping ((FileViewModel?, Error?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    completion(nil, APIError.parseError)
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, completion)
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
    private func navigateMin(params: NavigateMinParams, then handler: @escaping (([FileViewModel], Error?) -> Void)) {
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
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, sortOption: SortOption = .nameAscending, _ handler: @escaping (([FileViewModel], Error?) -> Void)) {
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
    
    private func getLeanItems(params: GetLeanItemsParams, then handler: @escaping (([FileViewModel], Error?) -> Void)) {
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
    
    private func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping (([FileViewModel], Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler([], APIError.clientError)
            return
        }
        
        var viewModels: [FileViewModel] = []
        childItems.forEach {
            let file = FileViewModel(model: $0, permissions: [], accessRole: .viewer)
            viewModels.append(file)
        }
        
        handler(viewModels, nil)
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ((FileViewModel?, Error?) -> Void)) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.displayName == Constants.API.FileType.myFilesFolder })
        else {
            handler(nil, APIError.clientError)
            return
        }
        
        let folder = FileViewModel(model: myFilesFolder)
        handler(folder, nil)
    }
}

class FilesRemoteMockDataSource: FilesRemoteDataSourceInterface {
    var folderContentMockFiles: [FileViewModel] = []
    var newFolderMock: FileViewModel?
    var privateRootMock: FileViewModel?
    
    func folderContent(archiveNo: String, folderLinkId: Int, completion: @escaping (([FileViewModel], Error?) -> Void)) {
        completion(folderContentMockFiles, nil)
    }
    
    func createNewFolder(name: String, folderLinkId: Int, completion: @escaping ((FileViewModel?, Error?) -> Void)) {
        completion(newFolderMock, nil)
    }
    
    func getPrivateRoot(completion: @escaping ((FileViewModel?, Error?) -> Void)) {
        completion(privateRootMock, nil)
    }
}

