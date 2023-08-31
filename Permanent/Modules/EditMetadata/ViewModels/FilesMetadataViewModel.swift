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
            let tags = Array(Set(selectedFiles.flatMap{ $0.tagVOS ?? [] }.map{ TagVO(tagVO: $0)}))
            allTags = tags.sorted()
            if selectedFiles.count > 1, !descriptionWasSaved {
                haveDiffDescription = selectedFiles.allSatisfy({ $0.description.isNotEmpty })
            }
        }
    }
    
    @Published var inputText: String = .enterTextHere
    @Published var didSaved: Bool = false {
        didSet {
            updateDescription(inputText)
        }
    }
    @Published var showAlert: Bool = false
    @Published var allTags: [TagVO] = [] {
        didSet {
            filteredAllTags = allTags.filter { tag in
                selectedFiles.allSatisfy { file in
                    file.tagVOS?.contains(where: { $0.name == tag.tagVO.name }) == true
                }
            }
        }
    }
    @Published var filteredAllTags: [TagVO] = [] {
        didSet {
            if selectedFiles.count > 1 {
                havePartialTags = allTags != filteredAllTags
            }
        }
    }
    @Published var haveDiffDescription: Bool = false
    @Published var havePartialTags: Bool = false
    @Published var hasUpdates: Bool = false
    
    @Published var locationSectionText: String = "Locations"
    
    var descriptionWasSaved: Bool = false
    var downloader: DownloadManagerGCD? = nil
    
    let tagsRepository: TagsRepository
    
    init(tagsRepository: TagsRepository = TagsRepository(), files: [FileModel]) {
        self.tagsRepository = tagsRepository
        self.selectedFiles = files
        refreshFiles()
    }
    
    func isTagInAllFiles(_ text: String) -> Bool {
        return filteredAllTags.contains(where: { $0.tagVO.name == text })
    }
    
    func refreshFiles() {
        Task {[weak self] in
            guard let strongSelf = self else { return }
            let records = try await strongSelf.selectedFiles.asyncMap(strongSelf.getRecord)
            await MainActor.run {
                strongSelf.setLocationsSectionText(records: records.compactMap{$0})
                
                strongSelf.selectedFiles = records.compactMap { record in
                    if let recordVO = record?.recordVO {
                        return FileModel(model: recordVO, permissions: [], accessRole: AccessRole.viewer)
                    }
                    return nil
                }
               
            }
        }
    }
    
    func updateDescription(_ text: String) {
        update(description: text) { status in
            if status {
                self.descriptionWasSaved = true
                self.haveDiffDescription = false
                self.refreshFiles()
            }
            self.showAlert = !status
        }
    }
    
    func getRecord(file: FileModel) async throws -> RecordVO? {
        return try await withCheckedThrowingContinuation {[weak self] continuation in
            let downloadInfo = FileDownloadInfoVM(
                fileType: file.type,
                folderLinkId: file.folderLinkId,
                parentFolderLinkId: file.parentFolderLinkId
            )
            
            self?.downloader = DownloadManagerGCD()
            self?.downloader?.getRecord(downloadInfo) { (record, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: record)
                }
            }
        }
    }
    
    func update(description: String, completion: @escaping ((Bool) -> Void)) {
        let params: UpdateMultipleRecordsParams = (files: selectedFiles, description: description, location: nil)
        let apiOperation = APIOperation(FilesEndpoint.multipleUpdate(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json( _, _):
                    self.hasUpdates = true
                    completion(true)
                    
                case .error(_, _):
                    completion(false)
                    
                default:
                    completion(false)
                }
            }
        }
    }
    
    //MARK: Sections
    
    private func setLocationsSectionText(records: [RecordVO]) {
        guard records.filter({ $0.recordVO?.locnVO != nil}).count > 0 else {
            locationSectionText = "Locations"
            return
        }
        let sameLocation = Set(records.compactMap { record in
            let locnVO = record.recordVO?.locnVO
            return getAddressString([locnVO?.streetNumber, locnVO?.streetName, locnVO?.locality, locnVO?.country])
        }).count == 1
        
        if sameLocation {
            let locnVO = records.first?.recordVO?.locnVO
            let address = getAddressString([locnVO?.streetNumber, locnVO?.streetName, locnVO?.locality, locnVO?.country])
            locationSectionText = address
        } else {
            locationSectionText = "Various locations"
        }
    }
    
    func getAddressString(_ items: [String?]) -> String {
        let address = items.compactMap { $0 }.joined(separator: ", ")
        return address
    }
    
    //MARK: Delete Tag
    
    func unassignTag(tagName: String, isLoading: Binding<Bool>) {
        isLoading.wrappedValue = true
        Task {[weak self] in
            guard let strongSelf = self else { return }
            guard let unAssignTag: TagVO = strongSelf.allTags.filter({ $0.tagVO.name == tagName }).first else { return }
            
            do {
                let files = strongSelf.selectedFiles.filter({ $0.tagVOS?.contains(unAssignTag.tagVO) ?? false })
                let _ = try await files.asyncMap({ file in
                    try await strongSelf.runUnassignTag(unassignTag: unAssignTag, recordId: file.recordId)
                })
                
                await MainActor.run {
                    isLoading.wrappedValue = false
                    strongSelf.allTags.removeAll(where: { $0.tagVO.name == tagName })
                }
            }
            catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    strongSelf.showAlert = true
                }
            }
            self?.hasUpdates = true
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
    
    //MARK: Assign Tags
    
    func assignAllTagsToAll() {
        Task {[weak self] in
            guard let strongSelf = self else { return }
            do {
                let _ = try await strongSelf.selectedFiles.compactMap { file in
                    return (strongSelf.allTags, file.recordId)
                }.asyncMap(strongSelf.runAssignTag)
                
                await MainActor.run {
                    strongSelf.refreshFiles()
                }
            }
            catch {
                await MainActor.run {
                    strongSelf.showAlert = true
                }
            }
        }
    }
    
    func assignTagToAll(tagName: String, isLoading: Binding<Bool>) {
        isLoading.wrappedValue = true
        Task {[weak self] in
            guard let strongSelf = self else { return }
            guard let tag: TagVO = strongSelf.allTags.filter({ $0.tagVO.name == tagName }).first else { return }
            do {
                let _ = try await strongSelf.selectedFiles.compactMap { file in
                    return ([tag], file.recordId)
                }.asyncMap(strongSelf.runAssignTag)
                
                await MainActor.run {
                    isLoading.wrappedValue = false
                    strongSelf.refreshFiles()
                }
            }
            catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    strongSelf.showAlert = true
                }
            }
        }
    }
    
    func runAssignTag(tags: [TagVO], recordId: Int) async throws {
        let tagNames = tags.compactMap { $0.tagVO.name }
        return try await withCheckedThrowingContinuation { continuation in
            tagsRepository.assignTag(tagNames: tagNames, recordId: recordId) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
