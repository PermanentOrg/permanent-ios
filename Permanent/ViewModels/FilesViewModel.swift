//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import UIKit.UITableView

typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, csrf: String)
typealias GetLeanItemsParams = (archiveNo: String, folderLinkIds: [Int], csrf: String)

class FilesViewModel: NSObject, ViewModelInterface {
    var viewModels: [FileViewModel] = []
    var csrf: String = ""
    var navigationStack: [FileViewModel] = []
    
    weak var delegate: FilesViewModelDelegate?
}

protocol FilesViewModelDelegate: ViewModelDelegateInterface {
    func getRoot(then handler: @escaping ServerResponse)
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse)
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse)
    func upload(files: [FileInfo], recordId: String, then handler: @escaping ServerResponse)
}

extension FilesViewModel: FilesViewModelDelegate {
    func upload(files: [FileInfo], recordId: String, then handler: @escaping ServerResponse) {
        let boundary = UploadManager.instance.createBoundary()
        let apiOperation = APIOperation(FilesEndpoint.upload(files: files, usingBoundary: boundary, recordId: recordId))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(_, _):
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getLeanItems(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetLeanItemsSuccess(model, handler)
                    
                } else {
                    handler(.error(message: Translations.errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func getRoot(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, handler)
                    
                } else {
                    handler(.error(message: Translations.errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                self.onNavigateMinSuccess(model, backNavigation, handler)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    private func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        self.viewModels.removeAll()
        
        childItems.forEach {
            let file = FileViewModel(model: $0)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let csrf = model.csrf
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems
            .compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let file = FileViewModel(model: folderVO)
            self.navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, folderLinkIds, csrf)
        getLeanItems(params: params, then: handler)
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let myFilesFolder = childItems.first(where: { $0.displayName == Constants.API.FileType.MY_FILES_FOLDER }),
            let archiveNo = myFilesFolder.archiveNbr,
            let folderLinkId = myFilesFolder.folderLinkID,
            let csrf = model.csrf
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        self.csrf = csrf
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, csrf)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
}
