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
    
    var tagVOs: [TagVOData] = []
    var filteredTags: [TagVOData] {
        get {
            return tagVOs.filter({
                if let searchQuery = searchQuery, searchQuery.count > 0 {
                    return ($0.name?.uppercased().contains(searchQuery.uppercased()) ?? false) || selectedTagVOs.map({ $0.name }).contains($0.name)
                } else {
                    return true
                }
            })
        }
    }
    var selectedTagVOs: [TagVOData] = [] {
        didSet {
            searchQuery = ""
            searchTimer?.invalidate()
            
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                self.reallySearchFiles(handler: { response in
                    NotificationCenter.default.post(name: NSNotification.Name("SearchFilesViewModel.didSearch"), object: self)
                })
                
                self.searchTimer?.invalidate()
                self.searchTimer = nil
            })
        }
    }
    
    override func shouldPerformAction(forSection section: Int) -> Bool {
        // Perform action only for synced items
        return section == FileListType.synced.rawValue && !currentFolderIsRoot
    }
    
    override func hasCancelButton(forSection section: Int) -> Bool {
        return false
    }
    
    override func title(forSection section: Int) -> String {
        switch section {
        case 0:
            if selectedTagVOs.count == 0 {
                return "Tags".localized()
            } else {
                return "Tags".localized() + " (\(selectedTagVOs.count))"
            }
        case 1: return currentFolderIsRoot ? "Results".localized() : activeSortOption.title
        default: return ""
        }
    }
    
    override var shouldDisplayBackgroundView: Bool {
        syncedViewModels.isEmpty && uploadQueue.isEmpty
    }
    
    override var numberOfSections: Int {
        2
    }
    
    override func numberOfRowsInSection(_ section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return syncedViewModels.count
        default: return 0
        }
    }
    
    func heightForSection(_ section: Int) -> Double {
        switch section {
        case 0: return 40
        case 1: return 40
        default: return 0
        }
    }
    
    override func fileForRowAt(indexPath: IndexPath) -> FileModel {
        switch indexPath.section {
        case 1:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func searchFiles(byQuery query: String, handler: @escaping ServerResponse) {
        searchTimer?.invalidate()
        searchQuery = query
        
        NotificationCenter.default.post(name: NSNotification.Name("SearchFilesViewModel.didChangeQuery"), object: self)

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            self.reallySearchFiles(handler: handler)
            
            self.searchTimer?.invalidate()
            self.searchTimer = nil
        })
    }
    
    func reallySearchFiles(handler: @escaping ServerResponse) {
        searchOperation?.cancel()
        searchOperation = nil
        guard (searchQuery?.count ?? 0) > 0 || selectedTagVOs.count > 0 else {
            self.navigationStack.removeAll()
            self.viewModels.removeAll()
            
            handler(.success)
            return
        }

        searchOperation = APIOperation(SearchEndpoint.folderAndRecord(text: searchQuery ?? "", tagVOs: selectedTagVOs))
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
                let searchedFileVMs = searchedItems.map({ FileModel(model: $0, permissions: self.archivePermissions, accessRole: self.archiveAccessRole) })
                self.viewModels.append(contentsOf: searchedFileVMs)
                
                handler(.success)

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }
    
    func getTags(completion: @escaping ServerResponse) {
        let params: GetTagsByArchiveParams = (currentArchive?.archiveID ?? 0)
        let apiOperation = APIOperation(TagEndpoint.getByArchive(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<TagVO> = JSONHelper.decoding(from: json, with: APIResults<TagVO>.decoder), model.isSuccessful else {
                    completion(.error(message: .errorMessage))
                    return
                }
                
                let tagVO: [TagVO]? =  model.results.first?.data
                self.tagVOs = tagVO?.map({ $0.tagVO }).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }) ?? []
                
                completion(.success)
            case .error(_, _):
                completion(.error(message: .errorMessage))
            default:
                completion(.error(message: .errorMessage))
            }
        }
    }
}
