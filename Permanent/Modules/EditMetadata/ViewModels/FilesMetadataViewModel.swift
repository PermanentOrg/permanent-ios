//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import SwiftUI
import Foundation

protocol GenericViewModelProtocol: ObservableObject {
    var selectedFiles: [FileModel] { get set }
}

class FilesMetadataViewModel: GenericViewModelProtocol {
    @Published var selectedFiles: [FileModel] = [] {
        didSet {
            allTags = selectedFiles.flatMap { $0.tagVOS ?? [] }
        }
    }
    @Published var inputText: String = .enterTextHere
    @Published var didSaved: Bool = false {
        didSet {
            updateDescription(inputText)
        }
    }
    @Published var showAlert: Bool = false
    @Published var allTags: [TagVOData] = []
    var downloader: DownloadManagerGCD? = nil
    
    init(files: [FileModel]) {
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
}
