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
    /// Both sides of the sheet. The gate's answer follows every change, so the line under the title is never stale.
    @Published var range: DateTimeRangeEntry {
        didSet { gateError = Self.gateError(for: range) }
    }
    /// True while the full view is open; a record with a qualifier or a range opens that way.
    @Published var showsOptions: Bool
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
    /// Test seam for one folder's V2 PATCH; production sends it to Stela.
    var patchFolderRequest: ((_ file: FileModel, _ fields: [String: Any], _ completion: @escaping (Bool) -> Void) -> Void)?
    var updateV1Request: ((_ files: [FileModel], _ completion: @escaping (Bool) -> Void) -> Void)?
    var sessionArchiveId: () -> Int?
    /// What one item read gives back; nil when the read failed.
    typealias RecordRead = (zone: String?, displayTime: String?)
    /// Test seam for the one-item read of the zone and `displayTime`; production reads them from Stela V2.
    var fetchRecordZone: ((_ file: FileModel, _ completion: @escaping (RecordRead?) -> Void) -> Void)?

    /// The zone the sheet opened with: given by the door, read once from the record, or guessed from the string's
    /// offset as web does. An unset against it sends null on save.
    private(set) var openingZone: String?
    private var openingRange: DateTimeRangeEntry
    private let recordZone: RecordZone
    private let guessedZone: String?
    private var didReadZone = false
    private var readsZone = false
    private var pendingReads: [Int] = []
    private var readsInFlight = 0
    static let maxConcurrentReads = 4
    /// A read with no answer by then counts as failed, so the sheet never waits forever.
    var readTimeout: TimeInterval = 15
    private var gateError: String?

    /// The From side, which the boxes, the wheels, the calendar and the zone list bind to.
    var entry: DateTimeEntry {
        get { range.start }
        set { range.start = newValue }
    }

    /// The To side, for the same views; an empty entry while the range is off.
    var endEntry: DateTimeEntry {
        get { range.end ?? DateTimeEntry() }
        set {
            guard range.isRange else { return }
            range.end = newValue
        }
    }

    /// True when every selected item saves to Stela V2, which alone can hold a qualifier or a range. A shared
    /// record saves through V1 as one moment, so it keeps the simple sheet.
    var offersMoreOptions: Bool {
        Self.savesToStela(selectedFiles, sessionArchiveId: sessionArchiveId())
    }

    /// Why edtf.js refuses the date, for the line under the title; nil when it accepts it. Save waits on it.
    var validation: String? {
        offersMoreOptions ? gateError : nil
    }

    init(
        selectedFiles: [FileModel], hasUpdates: Binding<Bool>, recordZone: RecordZone = .unknown,
        sessionArchiveId: @escaping () -> Int? = { AuthenticationManager.shared.session?.selectedArchive?.archiveID }
    ) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        self.recordZone = recordZone
        self.sessionArchiveId = sessionArchiveId

        var range = Self.commonEntry(for: selectedFiles, full: Self.opensFullSheet(selectedFiles, sessionArchiveId: sessionArchiveId()))
        guessedZone = Self.guessedZone(for: range.start) ?? range.end.flatMap(Self.guessedZone(for:))
        if case .known(let zone) = recordZone, let zone {
            range.start.timeZoneIdentifier = zone
        } else if selectedFiles.count > 1 {
            // A guess written to several files would replace each file's own zone.
            range.start.timeZoneIdentifier = nil
        } else if !Self.readsRecordZone(recordZone, fileCount: selectedFiles.count) {
            range.start.timeZoneIdentifier = guessedZone
        }
        self.range = range
        showsOptions = range.opensFull
        openingRange = range
        openingZone = range.start.timeZoneIdentifier
        gateError = Self.gateError(for: range)
    }

    /// Several files with nothing changed close without a request, so an untouched Save cannot drop their offsets.
    var closesWithoutSaving: Bool {
        selectedFiles.count > 1 && range.start == openingRange.start && range.end == openingRange.end
    }

    private static func savesToStela(_ files: [FileModel], sessionArchiveId: Int?) -> Bool {
        !files.isEmpty && files.allSatisfy { $0.savesDateToStela(sessionArchiveId: sessionArchiveId) }
    }

    /// One item alone that saves to Stela V2 reads every side of its date. Several items each read as one date,
    /// so a complex date among them stays for web.
    private static func opensFullSheet(_ files: [FileModel], sessionArchiveId: Int?) -> Bool {
        files.count == 1 && savesToStela(files, sessionArchiveId: sessionArchiveId)
    }

    /// True for a date this sheet must leave to web.
    private func blocksEdit(_ displayTime: String?) -> Bool {
        DateUtils.blocksDateEdit(displayTime, fullSheet: Self.opensFullSheet(selectedFiles, sessionArchiveId: sessionArchiveId()))
    }

    /// edtf.js's verdict on the string a save would send: an end that is not after the start, or any other refusal.
    private static func gateError(for range: DateTimeRangeEntry) -> String? {
        guard let gate = range.gateString else { return nil }
        do {
            _ = try JavaScriptCoreEDTF.shared.validated(gate)
            return nil
        } catch EDTFError.rejected(let reason) {
            return (reason.contains("upper bound") ? "DateRangeEndBeforeStart" : "DateCannotBeSaved").localized()
        } catch {
            // Without the library the server stays the judge, as in Stage 1.
            return nil
        }
    }

    // MARK: - More options

    func toggle(_ qualifier: DateQualifiers, on: Bool, side: DateTimeRangeEntry.Side = .start) {
        range.set(qualifier, on: on, side: side)
    }

    func setRange(on: Bool) {
        range.setRange(on: on)
    }

    /// Empties one side of a range. One date alone has no Clear: a save needs a date.
    func clear(_ side: DateTimeRangeEntry.Side) {
        range.clear(side)
    }

    // MARK: - Record read

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
        readsZone = opensAlone && selectedFiles.first?.savesDateToStela(sessionArchiveId: archiveId) == true
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

    /// A complex `displayTime` read here replaces the row's: a date for web keeps that file out of the save, and
    /// one the full sheet can read fills the sides the member has not touched. A failed read of a row with no
    /// `displayTime` leaves that row out of the save, since it may hide a date set on web.
    private func settle(recordDisplayTime answer: RecordRead?, at index: Int) {
        guard selectedFiles.indices.contains(index) else { return }
        guard let answer else {
            if (selectedFiles[index].displayTime ?? "").isEmpty { failedReads.insert(index) }
            return
        }
        guard DateUtils.isWebOnlyDate(answer.displayTime), answer.displayTime != selectedFiles[index].displayTime else { return }
        selectedFiles[index].displayTime = answer.displayTime
        guard !blocksEdit(answer.displayTime), range.start == openingRange.start, range.end == openingRange.end else { return }
        range = DateTimeRangeEntry(
            displayTime: answer.displayTime, legacy: selectedFiles[index].createdDT, timeZoneIdentifier: entry.timeZoneIdentifier
        )
        openingRange = range
        showsOptions = range.opensFull
    }

    /// The rows a save may change: read, and not a date for web.
    private var savableIndices: [Int] {
        selectedFiles.indices.filter { !failedReads.contains($0) && !blocksEdit(selectedFiles[$0].displayTime) }
    }

    private func finishReads() {
        isReadingRecord = false
        if selectedFiles.contains(where: { blocksEdit($0.displayTime) }) {
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
            let folder = model.items?.first
            completion((zone: folder?.location?.timezone, displayTime: folder?.displayTime))
        }
    }

    /// The date the files share, as the sheet's sides; a file with no date is left out. Empty when the dated
    /// files differ. Not `full`, each file reads as one date, and a date for web reads as none.
    static func commonEntry(for files: [FileModel], full: Bool = false) -> DateTimeRangeEntry {
        let entries = Set(files.map { file in
            full
                ? DateTimeRangeEntry(displayTime: file.displayTime, legacy: file.createdDT)
                : DateTimeRangeEntry(start: DateTimeEntry(displayTime: file.displayTime, legacy: file.createdDT))
        }.filter { !$0.isEmpty })
        guard entries.count == 1, let common = entries.first else { return DateTimeRangeEntry() }
        return common
    }

    // MARK: - Save

    /// Why Save is off, or nil when it can save. An empty Save would clear the date, which the sheet does not
    /// offer for now; on each side a later field needs the ones before it, and a time needs a full date and an
    /// hour. An empty side of a range is an open end. Last, edtf.js must accept the whole date.
    var saveBlockedReason: String? {
        if isReadingRecord { return "DateReading".localized() }
        if recordReadFailed { return "DateReadFailed".localized() }
        if range.isEmpty { return "SaveNeedsDate".localized() }
        for side in [range.start, range.end].compactMap({ $0 }) {
            if let reason = Self.blockedReason(for: side) { return reason }
        }
        return validation
    }

    private static func blockedReason(for side: DateTimeEntry) -> String? {
        if side.isEmpty { return nil }
        if side.year.isEmpty && !(side.month.isEmpty && side.day.isEmpty) { return "DateNeedsYear".localized() }
        if side.month.isEmpty && !side.day.isEmpty { return "DateNeedsMonth".localized() }
        let hasFullDate = !side.year.isEmpty && !side.month.isEmpty && !side.day.isEmpty
        if side.hasTime && !hasFullDate { return "TimeNeedsFullDate".localized() }
        if side.hasTime && side.hour.isEmpty { return "TimeNeedsHour".localized() }
        return nil
    }

    var canSave: Bool { saveBlockedReason == nil }

    func applyChanges() {
        guard !isReadingRecord, !recordReadFailed, validation == nil else { return }
        // A complex date is only changed on web, so its file never gets the new date.
        let savable = savableIndices
        guard !savable.isEmpty else {
            showWebOnlyMessage()
            return
        }
        selectedFiles = savable.map { selectedFiles[$0] }
        isLoading = true
        // One PATCH per item to Stela V2 `displayTime`, with the V1 batch as the failsafe. Any unsaved or
        // shared record sends the whole batch to V1, as the other batch edits do.
        guard offersMoreOptions else {
            applyChangesV1()
            return
        }
        let fields = patchFields
        // V1 writes one moment into the old field: it can stand in only for one plain date, and is seen only
        // while no record shows a `displayTime`. V1 cannot save a folder, so a folder's failed PATCH shows the
        // alert, as on web.
        let retriesV1 = !range.isEmpty && !range.opensFull && !selectedFiles.contains(where: \.type.isFolder)
            && DateUtils.showsLegacyDate(displayTimes: selectedFiles.map(\.displayTime))
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

    /// The V2 body: `displayTime`, null on a clear, which V1 cannot do. `location.timezone` goes when a side has a time
    /// and the zone is set, is null when the zone is unset or no side holds a date, and is left out otherwise.
    var patchFields: [String: Any] {
        var fields: [String: Any] = ["displayTime": range.edtfString.map { $0 as Any } ?? NSNull()]
        if range.hasTime, let zone = entry.zone {
            fields["location"] = ["timezone": zone.identifier]
        } else if range.holdsNoDate || (entry.timeZoneIdentifier == nil && openingZone != nil) {
            fields["location"] = ["timezone": NSNull()]
        }
        return fields
    }

    /// One PATCH per item, in order: a folder to the folder route, a record to the record route.
    private func patchEachRecord(fields: [String: Any], completion: @escaping (Bool) -> Void) {
        let patchRecord = patchRecordRequest ?? Self.patchRecordToV2
        let patchFolder = patchFolderRequest ?? Self.patchFolderToV2
        [FileModel].patchSequentially(files: selectedFiles, fieldsFor: { _ in fields }, patchOne: { file, fields, done in
            if file.type.isFolder {
                patchFolder(file, fields, done)
            } else {
                patchRecord(file, fields, done)
            }
        }, completion: completion)
    }

    private static func patchRecordToV2(file: FileModel, fields: [String: Any], completion: @escaping (Bool) -> Void) {
        [file].patchEachRecordToV2(fieldsFor: { _ in fields }, completion: completion)
    }

    private static func patchFolderToV2(file: FileModel, fields: [String: Any], completion: @escaping (Bool) -> Void) {
        let operation = APIOperation(FolderV2Endpoint.patchFolder(folderId: String(file.folderId), fields: fields))
        operation.execute(in: APIRequestDispatcher()) { result in
            if case .json = result {
                completion(true)
            } else {
                completion(false)
            }
        }
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
