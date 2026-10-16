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
    @Published var selectedDate = Date()
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
        
        selectedDate = getCommonDate()
    }
    
    func getCommonDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var dates = [Date]()
        for file in selectedFiles {
            if let date = DateUtils.date(fromDisplayTime: file.displayTime) ?? dateFormatter.date(from: file.createdDT ?? "") {
                dates.append(date)
            }
        }
        
        // Check if all dates are the same
        let uniqueDates = Set(dates)
        if uniqueDates.count == 1 {
            // If all dates are the same, return the common date
            return uniqueDates.first ?? Date()
        } else {
            // If dates are different, return the current date
            return Date()
        }
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
        let fields = DateUtils.displayTimeFields(for: selectedDate)
        // V1 writes only the old field, so its retry is seen only while no record shows a `displayTime`.
        let showsLegacyDate = DateUtils.showsLegacyDate(displayTimes: selectedFiles.map(\.displayTime))
        patchEachRecord(fields: fields) { [weak self] succeeded in
            if succeeded {
                self?.isLoading = false
                self?.hasUpdates.wrappedValue = true
                self?.changesWereSaved = true
            } else if showsLegacyDate {
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

    private func applyChangesV1() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = dateFormatter.string(from: selectedDate)
        
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
