//
//  FileModelLegacyDateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 16.11.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The V1 list rows (shares, shared folders, public roots) carry only the old date, so they hide it
/// while the server's edtf-date switch is on, like every other list.
struct FileModelLegacyDateTests {
    enum Source: String, CaseIterable {
        case item, minFolder, folder
    }

    private static let json = Data(#"{ "displayName": "Images", "displayDT": "2026-06-12T08:53:49" }"#.utf8)

    @Test("A V1 row shows the old date only while edtf-date is off", arguments: Source.allCases, [true, false])
    func legacyDateFollowsTheSwitch(source: Source, onlyEDTF: Bool) throws {
        let file = try Self.fileModel(source, onlyEDTF: onlyEDTF)

        #expect(file.date == (onlyEDTF ? "-" : "2026-06-12"))
        #expect(file.createdDT == "2026-06-12T08:53:49", "the old field stays for the V1 saves")
    }

    @Test("A V1 row with no date shows none", arguments: Source.allCases)
    func missingDateShowsDash(source: Source) throws {
        let empty = Data(#"{ "displayName": "Images" }"#.utf8)

        #expect(try Self.fileModel(source, onlyEDTF: false, json: empty).date == "-")
    }

    private static func fileModel(_ source: Source, onlyEDTF: Bool, json: Data = json) throws -> FileModel {
        let decoder = JSONDecoder()
        switch source {
        case .item:
            let model = try decoder.decode(ItemVO.self, from: json)
            return FileModel(model: model, permissions: [], accessRole: .viewer, onlyEDTF: onlyEDTF)
        case .minFolder:
            let model = try decoder.decode(MinFolderVO.self, from: json)
            return FileModel(model: model, permissions: [], accessRole: .viewer, onlyEDTF: onlyEDTF)
        case .folder:
            let model = try decoder.decode(FolderVOData.self, from: json)
            return FileModel(model: model, onlyEDTF: onlyEDTF)
        }
    }
}
