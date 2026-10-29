//
//  EditDateAndTimeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.08.2023.
//

import SwiftUI

class EditDateAndTimeViewModel: ObservableObject {
    var selectedFiles: [FileModel]
    var hasUpdates: Binding<Bool>
    
    @Published var isLoading: Bool = false
    @Published var changesConfirmed: Bool = false
    @Published var entry: DateTimeEntry
    @Published var showConfirmation: Bool = false
    @Published var changesWereSaved: Bool = false
    @Published var showAlert: Bool = false
    
    let startingDate: Date = Calendar.current.date(from: DateComponents(year: 1900)) ?? Date()
    let endingDate: Date = Date()

    /// Test seams for a save: one record's V2 PATCH, the V1 batch and the session's archive stand in
    /// for the server and the sign-in. Production leaves the requests nil.
    var patchRecordRequest: ((_ file: FileModel, _ fields: [String: Any], _ completion: @escaping (Bool) -> Void) -> Void)?
    var updateV1Request: ((_ files: [FileModel], _ completion: @escaping (Bool) -> Void) -> Void)?
    var sessionArchiveId: () -> Int? = { AuthenticationManager.shared.session?.selectedArchive?.archiveID }
    
    init(selectedFiles: [FileModel], hasUpdates: Binding<Bool>) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        
        entry = Self.commonEntry(for: selectedFiles)
    }

    /// The date the files share, as the fields; a file with no date is left out. Empty when the dated files differ.
    static func commonEntry(for files: [FileModel]) -> DateTimeEntry {
        let entries = Set(files.map { DateTimeEntry(displayTime: $0.displayTime, legacy: $0.createdDT) }.filter { !$0.isEmpty })
        guard entries.count == 1, let common = entries.first else { return DateTimeEntry() }
        return common
    }

    func applyChanges() {
        isLoading = true
        // One PATCH per record to Stela V2 `displayTime`, with the V1 batch as the failsafe. Any folder,
        // unsaved or shared record sends the whole batch to V1, as the other batch edits do.
        let archiveId = sessionArchiveId()
        guard !selectedFiles.isEmpty, selectedFiles.allSatisfy({ $0.savesDateToV2(sessionArchiveId: archiveId) }) else {
            applyChangesV1()
            return
        }
        // A clear sends null. V1 cannot empty the old field, so a clear never retries there.
        let fields: [String: Any] = ["displayTime": entry.edtfString.map { $0 as Any } ?? NSNull()]
        // V1 writes only the old field, so its retry is seen only while no record shows a `displayTime`.
        let retriesV1 = !entry.isEmpty && DateUtils.showsLegacyDate(displayTimes: selectedFiles.map(\.displayTime))
        patchEachRecord(fields: fields) { [weak self] succeeded in
            if succeeded {
                self?.isLoading = false
                self?.hasUpdates.wrappedValue = true
                self?.changesWereSaved = true
            } else if retriesV1 {
                self?.applyChangesV1() // failsafe
            } else {
                self?.isLoading = false
                self?.showAlert = true
            }
        }
    }

    private func patchEachRecord(fields: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let injected = patchRecordRequest else {
            selectedFiles.patchEachRecordToV2(fieldsFor: { _ in fields }, completion: completion)
            return
        }
        [FileModel].patchSequentially(files: selectedFiles, fieldsFor: { _ in fields }, patchOne: injected, completion: completion)
    }

    /// V1 takes the fields as a moment, as the old calendar sent it. It cannot clear, so an empty entry only reports.
    private func applyChangesV1() {
        guard !entry.isEmpty else {
            isLoading = false
            showAlert = true
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = dateFormatter.string(from: entry.pickerDate())
        
        let updatedFiles = selectedFiles.map { file in
            var newFile = file
            newFile.date = date
            return newFile
        }
        
        sendV1(updatedFiles) { [weak self] succeeded in
            DispatchQueue.main.async {
                self?.isLoading = false
                if succeeded {
                    self?.hasUpdates.wrappedValue = true
                    self?.changesWereSaved = true
                } else {
                    self?.showAlert = true
                }
            }
        }
    }

    private func sendV1(_ files: [FileModel], completion: @escaping (Bool) -> Void) {
        if let injected = updateV1Request {
            injected(files, completion)
            return
        }
        let apiOperation = APIOperation(FilesEndpoint.multipleFilesUpdate(files: files))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            if case .json = result {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
