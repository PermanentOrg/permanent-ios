//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import SwiftUI
import Foundation

class FilesMetadataViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    
    @Published var selectedFiles: [FileModel] = [] {
        didSet {
            let tags = Array(Set(selectedFiles.flatMap{ $0.tagVOS ?? [] }.map{ TagVO(tagVO: $0)}))
            allTags = tags.sorted()
            if !descriptionWasSaved {
                haveDiffDescription = !selectedFiles.allSatisfy({$0.description == selectedFiles.first?.description})
            }
            haveDiffDate = !selectedFiles.allSatisfy({$0.createdDT == selectedFiles.first?.createdDT})
            if haveDiffDescription {
                inputText = .enterTextHere
            } else {
                if let initialDesc = selectedFiles.first?.description, initialDesc.isNotEmpty {
                    inputText = initialDesc
                } else {
                    inputText = .enterTextHere
                }
            }
        }
    }
    @Published var inputText: String?
    @Published var didSaved: Bool = false {
        didSet {
            updateDescription(inputText ?? "")
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
    @Published var haveDiffDate: Bool = false 
    @Published var havePartialTags: Bool = false
    @Published var hasUpdates: Bool = false
    
    @Published var locationSectionText: String = "Locations"
    @Published var commonLocation: LocnVO?
    
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
        isLoading = true
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
                
                strongSelf.isLoading = false
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
        // Stela V2 read for records, with the legacy V1 fetch as an
        // automatic failsafe. Folders (recordId <= 0) always use V1.
        if file.recordId > 0, !file.type.isFolder {
            if let v2Record = await getRecordV2(file: file) {
                return v2Record
            }
            // any V2 miss (error / decode failure) → fall through to the V1 fetch
        }
        return try await getRecordV1(file: file)
    }

    private func getRecordV1(file: FileModel) async throws -> RecordVO? {
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

    /// Fetches the record via V2 and maps it into the legacy `RecordVO`, so the metadata editor is
    /// unchanged. Nil on any failure, so the caller falls back to V1.
    private func getRecordV2(file: FileModel) async -> RecordVO? {
        return await withCheckedContinuation { continuation in
            let operation = APIOperation(RecordV2Endpoint.getRecordById(recordId: String(file.recordId), shareToken: ""))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard
                        let model: RecordV2Response = JSONHelper.decoding(from: response, with: RecordV2Response.decoder),
                        let data = model.data,
                        let recordVO: RecordVO = JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder)
                    else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: recordVO)

                default:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func update(description: String, completion: @escaping ((Bool) -> Void)) {
        // One PATCH per record, with the V1 batch as an automatic failsafe. Records only: any folder or
        // unsaved record in the selection sends the whole batch to V1.
        if selectedFiles.allSatisfy({ $0.recordId > 0 && !$0.type.isFolder }) {
            selectedFiles.patchEachRecordToV2(fieldsFor: { _ in ["description": description] }) { [weak self] succeeded in
                if succeeded {
                    self?.hasUpdates = true
                    completion(true)
                } else {
                    self?.updateV1(description: description, completion: completion) // failsafe
                }
            }
            return
        }
        updateV1(description: description, completion: completion)
    }

    private func updateV1(description: String, completion: @escaping ((Bool) -> Void)) {
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
            updateLocation(locnVO)
            let address = getAddressString([locnVO?.streetNumber, locnVO?.streetName, locnVO?.locality, locnVO?.country])
            locationSectionText = address
        } else {
            locationSectionText = "Various locations"
        }
    }

    func updateLocation(_ location: LocnVO?) {
        commonLocation = location
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
    
    func getCommonDate() -> String {
        let dateFormatter = DateFormatter()
        // en_US_POSIX so parsing this Gregorian ISO string doesn't fail on a device set to a
        // non-Gregorian calendar (Buddhist/Persian), which would drop to `?? Date()` (today).
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let date = dateFormatter.date(from: selectedFiles.first?.createdDT ?? "") ?? Date()

        let dateFormatterChanged = DateFormatter()
        // Display-only, for the metadata date row. `en_US_POSIX` keeps the year Gregorian on devices
        // set to a non-Gregorian calendar.
        dateFormatterChanged.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterChanged.dateFormat = "yyyy-MM-dd hh:mm a"

        let commonDate = dateFormatterChanged.string(from: date)
        
        return commonDate
    }
}
