//
//  MetadataEditFileNamesViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2023.

import Foundation
import SwiftUI

protocol MetadataEditFilenamesProtocol: AnyObject {
    var fileNamePreview: Binding<String?> {get set}
    func getSelectedFiles() -> [FileModel]
}

class MetadataEditFileNamesViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var changesWereSaved: Bool = false
    
    var selectedFiles: [FileModel]
    let tagsRepository: TagsRepository
    @Published var imagePreviewURL: String?
    @Published var fileSizePreview: String?
    @Published var fileNamePreview: String?
    @Published var showConfirmation: Bool = false
    @Published var changesConfirmed: Bool = false
    var hasUpdates: Binding<Bool>
    
    var currentViewModel: (any MetadataEditFilenamesProtocol)?
    
    init(tagsRepository: TagsRepository = TagsRepository(), selectedFiles: [FileModel], hasUpdates: Binding<Bool>) {
        self.tagsRepository = tagsRepository
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        
        imagePreviewURL = selectedFiles.first?.thumbnailURL500
        fileNamePreview = selectedFiles.first?.name
        if let size = selectedFiles.first?.size {
            fileSizePreview = size.bytesToReadableForm(useDecimal: true)
        }
    }
    
    func applyChanges() {
        guard let updatedFiles = currentViewModel?.getSelectedFiles() else {
            return
        }
        isLoading = true
        let apiOperation = APIOperation(FilesEndpoint.multipleFilesUpdate(files: updatedFiles))
        
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .json( _, _):
                    self?.hasUpdates.wrappedValue = true
                    self?.changesWereSaved = true
                case .error(_, _):
                    self?.showAlert = true
                default:
                    self?.showAlert = true
                }
            }
        }
    }
}
