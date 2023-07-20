//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import SwiftUI
import Foundation

protocol GenericViewModelProtocol: ObservableObject {
    var selectedFiles: [FileModel] { get set }
    var allTags: [TagVO] { get set }
    func unassignTag(tagName: String, completion: @escaping ((Bool) -> Void))
}

class FilesMetadataViewModel: GenericViewModelProtocol {
    @Published var selectedFiles: [FileModel] = [] {
        didSet {
            allTags = selectedFiles.flatMap { $0.tagVOS ?? [] }.map { TagVO(tagVO: $0)}
        }
    }
    @Published var inputText: String = .enterTextHere
    @Published var didSaved: Bool = false {
        didSet {
            updateDescription(inputText)
        }
    }
    @Published var showAlert: Bool = false
    @Published var allTags: [TagVO] = []
    var downloader: DownloadManagerGCD? = nil
    
    let tagsRepository: TagsRepository
    
    init(tagsRepository: TagsRepository = TagsRepository(), files: [FileModel]) {
        self.tagsRepository = tagsRepository
        self.selectedFiles = files
        refreshFiles()
    }
    
    func refreshFiles() {
        let files = selectedFiles
        selectedFiles = []
        for file in files {
            getRecord(file: file) { [weak self] record in
                if let record = record?.recordVO {
                    self?.selectedFiles.append(FileModel(model: record, permissions: file.permissions, accessRole: file.accessRole))
                }
            }
        }
    }
    
    func updateDescription(_ text: String) {
        update(description: text) { status in
            self.showAlert = !status
        }
    }
    
    func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
        downloader?.getRecord(downloadInfo) { [weak self] (record, error) in
            handler(record)
        }
    }
    
    func update(description: String, completion: @escaping ((Bool) -> Void)) {
        let params: UpdateMultipleRecordsParams = (files: selectedFiles, description: description)
        let apiOperation = APIOperation(FilesEndpoint.multipleUpdate(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json( _, _):
                    completion(true)
                    
                case .error(_, _):
                    completion(false)
                    
                default:
                    completion(false)
                }
            }
        }
    }
    
    func unassignTag(tagName: String, completion: @escaping ((Bool) -> Void)) {
        guard let unAssignTag: TagVO = allTags.filter({ $0.tagVO.name == tagName }).first else { return }
        for file in selectedFiles {
            if ((file.tagVOS?.contains(unAssignTag.tagVO)) != nil) {
                tagsRepository.unassignTag(tagVO: [unAssignTag], recordId: file.recordId) { [weak self] error in
                    if error == nil {
                        self?.allTags.removeAll(where: { $0.tagVO.name == tagName })
                        //self?.refreshFiles()
                        completion(true)
                    } else {
                        self?.showAlert = true
                        completion(false)
                    }
                }
            }
        }
    }
}
