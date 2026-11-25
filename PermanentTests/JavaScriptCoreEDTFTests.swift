//
//  JavaScriptCoreEDTFTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// iOS runs Web's own edtf.js, so every string here must come back byte for byte. A changed byte
/// means iOS and Web would archive two different dates for one record.
@Suite
struct JavaScriptCoreEDTFTests {
    private let edtf = JavaScriptCoreEDTF.shared

    /// Every string edtf.js 4.10.1 emits that the server also accepts.
    static let conformance = [
        "1984", "1984-06", "1984-06-02",
        "1984?", "1984~", "1984%", "1984-06?", "1984-06-02~",
        "1984-XX", "1984-06-XX", "XXXX-12-XX", "201X", "19XX",
        "1964/2008", "1984-06-02/1984-06-08", "1984/..", "../1984", "1984/", "/1984",
        "1984-21", "1984-22", "1984-24", "1984-25", "1984-33",
        "[1667,1668,1670..1672]", "{1960,1961-12}",
        "Y170000002", "-1984",
        "1984?-06-02~"
    ]

    static let editable = [
        "1984", "1984-06", "1984-06-02", "-1984",
        "1984?", "1984~", "1984%", "1984-06?", "1984-06-02~",
        "1984-06-XX",
        "1964/2008", "1984-06-02/1984-06-08", "1984/..", "../1984", "1984/", "/1984"
    ]

    static let notEditable = [
        "1984-XX", "XXXX-12-XX", "201X", "19XX",
        "1984-21", "1984-22", "1984-24", "1984-25", "1984-33",
        "[1667,1668,1670..1672]", "{1960,1961-12}",
        "Y170000002",
        "1984?-06-02~"
    ]

    static let badInput = ["1984-13", "1984-02-30", "not-a-date", "1984//1985", ""]

    // MARK: - Conformance

    @Test("The conformance lists cover every string once")
    func listsAreComplete() {
        #expect(Self.conformance.count == 29)
        #expect(Set(Self.editable + Self.notEditable) == Set(Self.conformance))
    }

    @Test("edtf.js returns every conformance string unchanged", arguments: conformance)
    func validatedKeepsBytes(text: String) throws {
        #expect(try edtf.validated(text) == text)
    }

    @Test("A string the editor can hold comes back unchanged through its parts", arguments: editable)
    func roundTripsThroughParts(text: String) throws {
        let emitted: String
        switch try edtf.value(from: text) {
        case .date(let parts):
            emitted = try edtf.string(from: parts)

        case .interval(let interval):
            emitted = try edtf.string(from: interval)
        }
        #expect(emitted == text)
    }

    @Test("A string the editor cannot hold is refused, not misread", arguments: notEditable)
    func refusesWhatPartsCannotHold(text: String) {
        let error = #expect(throws: EDTFError.self) { try edtf.value(from: text) }
        #expect(error != .unavailable)
    }

    @Test("Bad input is rejected", arguments: badInput)
    func rejectsBadInput(text: String) {
        let error = #expect(throws: EDTFError.self) { try edtf.validated(text) }
        #expect(error != .unavailable)
    }

    @Test("A qualifier on a part the date does not have is refused")
    func refusesQualifierPastPrecision() {
        let parts = EDTFDateParts(year: 1984, uncertain: true, scope: .day)
        let error = #expect(throws: EDTFError.self) { try edtf.string(from: parts) }
        #expect(error != .unavailable)
    }

    // MARK: - Timezone rule

    @Test("A datetime with no zone is refused, so the device timezone never reaches the archive")
    func refusesZonelessDatetime() {
        let error = #expect(throws: EDTFError.self) { try edtf.validated("1984-06-02T14:30:00") }
        #expect(error != .unavailable)
    }

    @Test("A datetime in UTC keeps its wall-clock time")
    func keepsUTCDatetime() throws {
        #expect(try edtf.validated("1984-06-02T14:30:00Z") == "1984-06-02T14:30:00.000Z")
    }

    @Test("A date with no time stays the same date")
    func keepsDate() throws {
        #expect(try edtf.validated("1984-06-02") == "1984-06-02")
    }

    // MARK: - Threading

    @Test("Fifty calls at once each get their own answer")
    func concurrentCallsStayApart() async throws {
        let texts = (0..<50).map { Self.editable[$0 % Self.editable.count] }
        let pairs = try await withThrowingTaskGroup(of: (String, String).self) { group in
            for text in texts {
                group.addTask { (text, try JavaScriptCoreEDTF.shared.validated(text)) }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        #expect(pairs.count == 50)
        for (sent, received) in pairs {
            #expect(received == sent)
        }
    }
}
