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
    /// Set when the record read shows a complex date: the sheet shows the web-only message and closes.
    @Published var showsWebOnlyDate: Bool = false
    /// True while a list door reads its item; a row may hide a date set on web until the read returns.
    @Published private(set) var isReadingRecord = false
    /// Rows with no `displayTime` whose read failed; they may hide a date set on web, so Save leaves them out.
    @Published private(set) var failedReads: Set<Int> = []
    /// True when any read failed; Save stays off so no file is skipped without the member knowing.
    var recordReadFailed: Bool { !failedReads.isEmpty }
    /// The text of the web-only message, set when it shows.
    private(set) var webOnlyMessage = WebOnlyDateMessage.singleMessage
    
    let startingDate: Date = Calendar.current.date(from: DateComponents(year: 1900)) ?? Date()
    let endingDate: Date = Date()

    /// Test seams for a save: one record's V2 PATCH, the V1 batch and the session's archive stand in
    /// for the server and the sign-in. Production leaves the requests nil.
    var patchRecordRequest: ((_ file: FileModel, _ fields: [String: Any], _ completion: @escaping (Bool) -> Void) -> Void)?
    var updateV1Request: ((_ files: [FileModel], _ completion: @escaping (Bool) -> Void) -> Void)?
    var sessionArchiveId: () -> Int? = { AuthenticationManager.shared.session?.selectedArchive?.archiveID }
    /// What one item read gives back; nil when the read failed.
    typealias RecordRead = (zone: String?, displayTime: String?)
    /// Test seam for the one-item read of the zone and `displayTime`; production reads them from Stela V2.
    var fetchRecordZone: ((_ file: FileModel, _ completion: @escaping (RecordRead?) -> Void) -> Void)?

    /// The zone the sheet opened with: given by the door, read once from the record, or guessed from the string's
    /// offset as web does. An unset against it sends null on save.
    private(set) var openingZone: String?
    private let openingEntry: DateTimeEntry
    private let recordZone: RecordZone
    private let guessedZone: String?
    private var didReadZone = false
    private var readsZone = false
    private var pendingReads: [Int] = []
    private var readsInFlight = 0
    static let maxConcurrentReads = 4
    /// A read with no answer by then counts as failed, so the sheet never waits forever.
    var readTimeout: TimeInterval = 15
    
    init(selectedFiles: [FileModel], hasUpdates: Binding<Bool>, recordZone: RecordZone = .unknown) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        self.recordZone = recordZone
        
        var entry = Self.commonEntry(for: selectedFiles)
        guessedZone = Self.guessedZone(for: entry)
        if case .known(let zone) = recordZone, let zone {
            entry.timeZoneIdentifier = zone
        } else if selectedFiles.count > 1 {
            // A guess written to several files would replace each file's own zone.
            entry.timeZoneIdentifier = nil
        } else if !Self.readsRecordZone(recordZone, fileCount: selectedFiles.count) {
            entry.timeZoneIdentifier = guessedZone
        }
        self.entry = entry
        openingEntry = entry
        openingZone = entry.timeZoneIdentifier
    }

    /// Several files with nothing changed close without a request, so an untouched Save cannot drop their offsets.
    var closesWithoutSaving: Bool {
        selectedFiles.count > 1 && entry == openingEntry
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

    /// The sheet reads, once, what a list row may lack: an own record's zone when it opens alone, and the
    /// `displayTime` of every row that came without one. The Info door skips it. Save waits for every read.
    func readZoneIfNeeded() {
        guard !didReadZone, recordZone == .unknown else { return }
        didReadZone = true
        let archiveId = sessionArchiveId()
        let opensAlone = Self.readsRecordZone(recordZone, fileCount: selectedFiles.count)
        readsZone = opensAlone && selectedFiles.first?.savesDateToV2(sessionArchiveId: archiveId) == true
        if opensAlone && !readsZone {
            settle(recordZone: nil)
        }
        let reads = selectedFiles.indices.filter { (readsZone && $0 == 0) || (selectedFiles[$0].displayTime ?? "").isEmpty }
        guard !reads.isEmpty else { return }
        isReadingRecord = true
        pendingReads = reads
        startNextReads()
    }

    /// Starts reads until `maxConcurrentReads` run at once; each answer starts the next.
    private func startNextReads() {
        let read = fetchRecordZone ?? Self.readFromV2
        while readsInFlight < Self.maxConcurrentReads, !pendingReads.isEmpty {
            let index = pendingReads.removeFirst()
            readsInFlight += 1
            var isDone = false
            let timer = DispatchSource.makeTimerSource(queue: .main)
            let finish: (RecordRead?) -> Void = { [weak self] answer in
                guard !isDone else { return }
                isDone = true
                timer.cancel()
                self?.finishRead(answer, at: index)
            }
            timer.setEventHandler { finish(nil) }
            timer.schedule(deadline: .now() + readTimeout)
            timer.resume()
            read(selectedFiles[index]) { answer in
                DispatchQueue.main.async { finish(answer) }
            }
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

    private func finishRead(_ answer: RecordRead?, at index: Int) {
        if index == 0 && readsZone {
            settle(recordZone: answer?.zone)
        }
        settle(recordDisplayTime: answer, at: index)
        readsInFlight -= 1
        if readsInFlight == 0 && pendingReads.isEmpty {
            finishReads()
        } else {
            startNextReads()
        }
    }

    /// A complex `displayTime` read here replaces the row's, so that file is not saved. A failed read of a row
    /// with no `displayTime` leaves that row out of the save, since it may hide a date set on web.
    private func settle(recordDisplayTime answer: RecordRead?, at index: Int) {
        guard selectedFiles.indices.contains(index) else { return }
        guard let answer else {
            if (selectedFiles[index].displayTime ?? "").isEmpty { failedReads.insert(index) }
            return
        }
        guard DateUtils.isComplexDate(answer.displayTime) else { return }
        selectedFiles[index].displayTime = answer.displayTime
    }

    /// The rows a save may change: read, and not a complex date.
    private var savableIndices: [Int] {
        selectedFiles.indices.filter { !failedReads.contains($0) && !DateUtils.isComplexDate(selectedFiles[$0].displayTime) }
    }

    private func finishReads() {
        isReadingRecord = false
        if selectedFiles.contains(where: { DateUtils.isComplexDate($0.displayTime) }) {
            showWebOnlyMessage()
        }
    }

    /// Counted before Save drops any file.
    private func showWebOnlyMessage() {
        webOnlyMessage = WebOnlyDateMessage.message(for: selectedFiles)
        showsWebOnlyDate = true
    }

    private static func readFromV2(file: FileModel, completion: @escaping (RecordRead?) -> Void) {
        guard !file.type.isFolder else {
            readFolderFromV2(file: file, completion: completion)
            return
        }
        let operation = APIOperation(RecordV2Endpoint.getRecordById(recordId: String(file.recordId), shareToken: ""))
        operation.execute(in: APIRequestDispatcher()) { result in
            guard case .json(let response, _) = result,
                  let model: RecordV2Response = JSONHelper.decoding(from: response, with: RecordV2Response.decoder) else {
                completion(nil)
                return
            }
            completion((zone: model.data?.location?.timezone, displayTime: model.data?.displayTime))
        }
    }

    private static func readFolderFromV2(file: FileModel, completion: @escaping (RecordRead?) -> Void) {
        let operation = APIOperation(FolderV2Endpoint.getFolderById(folderId: String(file.folderId), shareToken: ""))
        operation.execute(in: APIRequestDispatcher()) { result in
            guard case .json(let response, _) = result,
                  let model: FolderV2Response = JSONHelper.decoding(from: response, with: FolderV2Response.decoder) else {
                completion(nil)
                return
            }
            completion((zone: nil, displayTime: model.items?.first?.displayTime))
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
        if isReadingRecord { return "DateReading".localized() }
        if recordReadFailed { return "DateReadFailed".localized() }
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
        guard !isReadingRecord, !recordReadFailed else { return }
        // A complex date is only changed on web, so its file never gets the new date.
        let savable = savableIndices
        guard !savable.isEmpty else {
            showWebOnlyMessage()
            return
        }
        selectedFiles = savable.map { selectedFiles[$0] }
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
