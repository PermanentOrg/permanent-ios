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
    /// True while the full view is open under the Clear row; a record with a qualifier or a range opens that way.
    @Published var showsOptions: Bool
    @Published var showConfirmation: Bool = false
    @Published var changesWereSaved: Bool = false
    @Published var showAlert: Bool = false
    
    let startingDate: Date = Calendar.current.date(from: DateComponents(year: 1900)) ?? Date()
    let endingDate: Date = Date()

    /// Test seams for a save: one record's V2 PATCH, the V1 batch and the session's archive stand in
    /// for the server and the sign-in. Production leaves the requests nil.
    var patchRecordRequest: ((_ file: FileModel, _ fields: [String: Any], _ completion: @escaping (Bool) -> Void) -> Void)?
    var updateV1Request: ((_ files: [FileModel], _ completion: @escaping (Bool) -> Void) -> Void)?
    var sessionArchiveId: () -> Int?
    /// Test seam for the one-file read of the record's zone; production reads it from Stela V2.
    var fetchRecordZone: ((_ file: FileModel, _ completion: @escaping (String?) -> Void) -> Void)?

    /// The zone the sheet opened with: given by the door, read once from the record, or guessed from the string's
    /// offset as web does. An unset against it sends null on save.
    private(set) var openingZone: String?
    private let recordZone: RecordZone
    private let guessedZone: String?
    private var didReadZone = false
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

    /// True when every selected file saves to Stela V2, which alone can hold a qualifier or a range. A shared
    /// record saves through V1 as one moment, so it keeps the simple sheet.
    var offersMoreOptions: Bool {
        Self.savesToV2(selectedFiles, sessionArchiveId: sessionArchiveId())
    }

    /// Why the date cannot be saved, for the line under the title; nil when edtf.js accepts it. Save waits on it.
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

        var range = Self.commonEntry(for: selectedFiles, full: Self.savesToV2(selectedFiles, sessionArchiveId: sessionArchiveId()))
        guessedZone = Self.guessedZone(for: range.start) ?? range.end.flatMap(Self.guessedZone(for:))
        if case .known(let zone) = recordZone, let zone {
            range.start.timeZoneIdentifier = zone
        } else if !Self.readsRecordZone(recordZone, fileCount: selectedFiles.count) {
            range.start.timeZoneIdentifier = guessedZone
        }
        self.range = range
        showsOptions = range.opensFull
        openingZone = range.start.timeZoneIdentifier
        gateError = Self.gateError(for: range)
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

    private static func savesToV2(_ files: [FileModel], sessionArchiveId: Int?) -> Bool {
        !files.isEmpty && files.allSatisfy { $0.savesDateToV2(sessionArchiveId: sessionArchiveId) }
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

    func clear() {
        range.clear()
    }

    func clear(_ side: DateTimeRangeEntry.Side) {
        range.clear(side)
    }

    // MARK: - Zone

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

    /// The date the files share, as the sheet's sides; a file with no date is left out. Empty when the dated
    /// files differ. Not `full`, each file reads as one date: its first written side, without qualifiers.
    static func commonEntry(for files: [FileModel], full: Bool = true) -> DateTimeRangeEntry {
        let entries = Set(files.map { file in
            full
                ? DateTimeRangeEntry(displayTime: file.displayTime, legacy: file.createdDT)
                : DateTimeRangeEntry(start: DateTimeEntry(displayTime: file.displayTime, legacy: file.createdDT))
        }.filter { !$0.isEmpty })
        guard entries.count == 1, let common = entries.first else { return DateTimeRangeEntry() }
        return common
    }

    // MARK: - Save

    func applyChanges() {
        guard validation == nil else { return }
        isLoading = true
        // One PATCH per record to Stela V2 `displayTime`, with the V1 batch as the failsafe. Any folder,
        // unsaved or shared record sends the whole batch to V1, as the other batch edits do.
        guard offersMoreOptions else {
            applyChangesV1()
            return
        }
        let fields = patchFields
        // V1 writes one moment into the old field: it can stand in only for one plain date, and is seen only
        // while no record shows a `displayTime`.
        let retriesV1 = !range.isEmpty && !range.opensFull && DateUtils.showsLegacyDate(displayTimes: selectedFiles.map(\.displayTime))
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
