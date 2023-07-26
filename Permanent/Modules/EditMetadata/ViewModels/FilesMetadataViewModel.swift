//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import SwiftUI
import Foundation

class FilesMetadataViewModel: ObservableObject {
    @Published var selectedFiles: [FileModel] = [] {
        didSet {
            allTags = Array(Set(selectedFiles.flatMap{ $0.tagVOS ?? [] }.map{ TagVO(tagVO: $0)}))
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
        downloader?.getRecord(downloadInfo) { (record, error) in
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
        Task {[weak self] in
            guard let strongSelf = self else { return }
            guard let unAssignTag: TagVO = strongSelf.allTags.filter({ $0.tagVO.name == tagName }).first else { return }
            
            do {
                let files = strongSelf.selectedFiles.filter({ $0.tagVOS?.contains(unAssignTag.tagVO) ?? false })
                let _ = try await files.asyncMap({ file in
                    try await strongSelf.runUnassignTag(unassignTag: unAssignTag, recordId: file.recordId)
                })
                
                await MainActor.run {
                    strongSelf.allTags.removeAll(where: { $0.tagVO.name == tagName })
                }
            }
            catch {
                await MainActor.run {
                    strongSelf.showAlert = true
                }
            }
        }
    }
    
    func runUnassignTag(unassignTag: TagVO, recordId: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            tagsRepository.unassignTag(tagVO: [unassignTag], recordId: recordId) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
