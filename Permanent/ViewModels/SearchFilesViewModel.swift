//
//  SearchFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.11.2021.
//

import Foundation

class SearchFilesViewModel: FilesViewModel {
    
    override var currentFolderIsRoot: Bool { return navigationStack.count == 0 }
    
    var searchTimer: Timer?
    var searchQuery: String?
    var searchOperation: APIOperation?
    
    override func shouldPerformAction(forSection section: Int) -> Bool {
        // Perform action only for synced items
        return section == FileListType.synced.rawValue && !currentFolderIsRoot
    }
    
    override func hasCancelButton(forSection section: Int) -> Bool {
        return false
    }
    
    override func title(forSection section: Int) -> String {
        switch section {
        case 0: return currentFolderIsRoot ? "Results".localized() : activeSortOption.title
        default: return ""
        }
    }
    
    override var shouldDisplayBackgroundView: Bool {
        syncedViewModels.isEmpty && uploadQueue.isEmpty
    }
    
    override var numberOfSections: Int {
        1
    }
    
    override func numberOfRowsInSection(_ section: Int) -> Int {
        switch section {
        case 0: return syncedViewModels.count
        default: return 0
        }
    }
    
    override func fileForRowAt(indexPath: IndexPath) -> FileViewModel {
        switch indexPath.section {
        case 0:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func searchFiles(byQuery query: String, handler: @escaping ServerResponse) {
        searchTimer?.invalidate()
        searchQuery = query

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            self.reallySearchFiles(handler: handler)
            
            self.searchTimer?.invalidate()
            self.searchTimer = nil
        })
    }
    
    func reallySearchFiles(handler: @escaping ServerResponse) {
        searchOperation?.cancel()
        searchOperation = nil
        guard let searchQuery = searchQuery, searchQuery.count > 0 else {
            self.navigationStack.removeAll()
            self.viewModels.removeAll()
            
            handler(.success)
            return
        }

        searchOperation = APIOperation(SearchEndpoint.folderAndRecord(text: searchQuery))
        searchOperation?.execute(in: APIRequestDispatcher()) { result in
            self.searchOperation = nil
            
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<SearchVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SearchVO>.decoder
                    ),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                self.navigationStack.removeAll()
                self.viewModels.removeAll()
                let searchedItems = model.results[0].data?[0].searchVO.childItemVOs ?? []
                let searchedFileVMs = searchedItems.map({ FileViewModel(model: $0, permissions: self.archivePermissions) })
                self.viewModels.append(contentsOf: searchedFileVMs)
                handler(.success)

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }
}
