//
//  EditDateAndTimeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.08.2023.
//

import SwiftUI

class EditDateAndTimeViewModel: ObservableObject {
    /// What the door knows of the record's zone: the Info screen passes what it read, a list door nothing.
    enum RecordZone: Equatable {
        case unknown
        case known(String?)
    }

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
    /// Test seam for the one-file read of the record's zone; production reads it from Stela V2.
    var fetchRecordZone: ((_ file: FileModel, _ completion: @escaping (String?) -> Void) -> Void)?

    /// The zone the sheet opened with: given by the door, read once from the record, or guessed from the string's
    /// offset as web does. An unset against it sends null on save.
    private(set) var openingZone: String?
    private let recordZone: RecordZone
    private let guessedZone: String?
    private var didReadZone = false
    
    init(selectedFiles: [FileModel], hasUpdates: Binding<Bool>, recordZone: RecordZone = .unknown) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        self.recordZone = recordZone
        
        var entry = Self.commonEntry(for: selectedFiles)
        guessedZone = Self.guessedZone(for: entry)
        if case .known(let zone) = recordZone, let zone {
            entry.timeZoneIdentifier = zone
        } else if !Self.readsRecordZone(recordZone, fileCount: selectedFiles.count) {
            entry.timeZoneIdentifier = guessedZone
        }
        self.entry = entry
        openingZone = entry.timeZoneIdentifier
    }

    /// One file's sheet. The Info door passes the record it read, so the fields and the zone start from it; a list
    /// door passes none, and the sheet reads the record once itself.
    convenience init(file: FileModel, record: RecordVOData?, hasUpdates: Binding<Bool>) {
        self.init(
            selectedFiles: [record.map(file.withDates(of:)) ?? file],
            hasUpdates: hasUpdates,
            recordZone: record.map { .known($0.timezone) } ?? .unknown
        )
    }

    /// A list door opens one record with its zone unknown; the row stays empty until the record is read.
    private static func readsRecordZone(_ recordZone: RecordZone, fileCount: Int) -> Bool {
        recordZone == .unknown && fileCount == 1
    }

    /// Web's guess for a string with an offset and no zone: the first zone whose offset at that clock time matches.
    static func guessedZone(for entry: DateTimeEntry) -> String? {
        guard let offset = entry.storedOffset.flatMap(TimeZoneOption.minutes(inOffset:)), let clock = entry.wallClock else { return nil }
        return TimeZoneCatalog.firstIdentifier(matchingOffset: offset, at: clock)
    }

    /// A list door reads its one record once; a V1 record has no zone to read. A batch and the Info door skip it.
    func readZoneIfNeeded() {
        guard !didReadZone, Self.readsRecordZone(recordZone, fileCount: selectedFiles.count), let file = selectedFiles.first else { return }
        didReadZone = true
        guard file.savesDateToV2(sessionArchiveId: sessionArchiveId()) else {
            settle(recordZone: nil)
            return
        }
        let read = fetchRecordZone ?? Self.readZoneFromV2
        read(file) { [weak self] zone in
            DispatchQueue.main.async { self?.settle(recordZone: zone) }
        }
    }

    /// The record's zone, or web's guess when it has none, fills the row unless the member chose one meanwhile.
    private func settle(recordZone zone: String?) {
        let opening = zone ?? guessedZone
        if entry.timeZoneIdentifier == openingZone {
            entry.timeZoneIdentifier = opening
        }
        openingZone = opening
    }

    private static func readZoneFromV2(file: FileModel, completion: @escaping (String?) -> Void) {
        let operation = APIOperation(RecordV2Endpoint.getRecordById(recordId: String(file.recordId), shareToken: ""))
        operation.execute(in: APIRequestDispatcher()) { result in
            guard case .json(let response, _) = result,
                  let model: RecordV2Response = JSONHelper.decoding(from: response, with: RecordV2Response.decoder) else {
                completion(nil)
                return
            }
            completion(model.data?.location?.timezone)
        }
    }

    /// The date the files share, as the fields; a file with no date is left out. Empty when the dated files differ.
    static func commonEntry(for files: [FileModel]) -> DateTimeEntry {
        let entries = Set(files.map { DateTimeEntry(displayTime: $0.displayTime, legacy: $0.createdDT) }.filter { !$0.isEmpty })
        guard entries.count == 1, let common = entries.first else { return DateTimeEntry() }
        return common
    }

    /// Why Save is off, or nil when it can save. An empty Save would clear the date, which the sheet does not
    /// offer for now; a later field needs the ones before it, and a time needs a full date and an hour.
    var saveBlockedReason: String? {
        if entry.isEmpty { return "SaveNeedsDate".localized() }
        if entry.year.isEmpty && !(entry.month.isEmpty && entry.day.isEmpty) { return "DateNeedsYear".localized() }
        if entry.month.isEmpty && !entry.day.isEmpty { return "DateNeedsMonth".localized() }
        let hasFullDate = !entry.year.isEmpty && !entry.month.isEmpty && !entry.day.isEmpty
        if entry.hasTime && !hasFullDate { return "TimeNeedsFullDate".localized() }
        if entry.hasTime && entry.hour.isEmpty { return "TimeNeedsHour".localized() }
        return nil
    }

    var canSave: Bool { saveBlockedReason == nil }

    func applyChanges() {
        isLoading = true
        // One PATCH per record to Stela V2 `displayTime`, with the V1 batch as the failsafe. Any folder,
        // unsaved or shared record sends the whole batch to V1, as the other batch edits do.
        let archiveId = sessionArchiveId()
        guard !selectedFiles.isEmpty, selectedFiles.allSatisfy({ $0.savesDateToV2(sessionArchiveId: archiveId) }) else {
            applyChangesV1()
            return
        }
        let fields = patchFields
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

    /// The V2 body: `displayTime`, null on a clear, which V1 cannot do. `location.timezone` goes with a time and a
    /// zone, is null when the zone is unset against the opening one or the date is cleared, and is left out otherwise.
    var patchFields: [String: Any] {
        var fields: [String: Any] = ["displayTime": entry.edtfString.map { $0 as Any } ?? NSNull()]
        if entry.hasTime, let zone = entry.zone {
            fields["location"] = ["timezone": zone.identifier]
        } else if entry.isEmpty || (entry.timeZoneIdentifier == nil && openingZone != nil) {
            fields["location"] = ["timezone": NSNull()]
        }
        return fields
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
