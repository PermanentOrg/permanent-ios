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
    @Published var selectedFiles: [FileModel] = []
    @Published var inputText: String = "Enter your text here"
    @Published var didSaved: Bool = false {
        didSet {
            updateDescription(inputText)
        }
    }
    @Published var showAlert: Bool = false
    
    init(files: [FileModel]) {
        self.selectedFiles = files
    }

    func updateDescription(_ text: String) {
        update(description: text) { status in
            self.showAlert = status
        }
    }
    
    func update(description: String, completion: @escaping ((Bool) -> Void)) {
        guard let selectedArchive = AuthenticationManager.shared.session?.selectedArchive else {
            completion(false)
            return
        }
        
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
