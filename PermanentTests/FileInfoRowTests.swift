//
//  FileInfoRowTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Permanent

/// The Info tab's row: its text, icon, VoiceOver reading and height in both styles.
@MainActor
struct FileInfoRowTests {
    typealias Kind = FileInfoRowModel.Kind
    typealias Style = FileInfoRowModel.Style

    private let values: [Kind: String] = [
        .name: "August_Hike_003", .description: "Picnic", .date: "October 23, 1985 • 5PM", .location: "Yamanakako, Japan"
    ]
    private let titles: [Kind: String] = [.name: "Name", .description: "Description", .date: "Date", .location: "Location"]
    private let placeholders: [Kind: String] = [
        .name: "", .description: "Add description...", .date: "Add date and time...", .location: "Add location..."
    ]
    private let defaultSize = UITraitCollection(preferredContentSizeCategory: .large)

    @Test("A boxed row with a value shows it in white with a pencil, and reads as a button with the edit hint", arguments: Kind.allCases)
    func boxedSetRow(kind: Kind) throws {
        let value = try #require(values[kind])
        let row = FileInfoRowModel(kind: kind, value: value, style: .boxed)

        #expect(row.isSet)
        #expect(row.title == titles[kind])
        #expect(row.text == value)
        #expect(row.iconName == "square.and.pencil")
        #expect(row.isButton)
        #expect(row.accessibilityLabel == "\(titles[kind] ?? ""), \(value)")
        #expect(row.accessibilityHint == "Double tap to edit")
    }

    @Test("An empty boxed row shows its placeholder with a plus", arguments: Kind.allCases)
    func boxedEmptyRow(kind: Kind) {
        for value in [nil, ""] {
            let row = FileInfoRowModel(kind: kind, value: value, style: .boxed)

            #expect(!row.isSet)
            #expect(row.text == placeholders[kind])
            #expect(row.iconName == "plus")
            #expect(row.isButton)
            #expect(row.accessibilityLabel == "\(titles[kind] ?? ""), \(placeholders[kind] ?? "")")
        }
    }

    @Test("A plain row has no icon, no hint and is not a button", arguments: Kind.allCases)
    func plainRow(kind: Kind) throws {
        let value = try #require(values[kind])
        let row = FileInfoRowModel(kind: kind, value: value, style: .plain)

        #expect(row.text == value)
        #expect(row.iconName == nil)
        #expect(!row.isButton)
        #expect(row.accessibilityLabel == "\(titles[kind] ?? ""), \(value)")
        #expect(row.accessibilityHint == nil)
    }

    @Test("Name and description are typed in place; date and location open a screen")
    func typedKinds() {
        #expect(FileInfoRowModel(kind: .name, value: "A", style: .boxed).isTyped)
        #expect(FileInfoRowModel(kind: .description, value: "A", style: .boxed).isTyped)
        #expect(!FileInfoRowModel(kind: .date, value: "A", style: .boxed).isTyped)
        #expect(!FileInfoRowModel(kind: .location, value: "A", style: .boxed).isTyped)
    }

    @Test("A boxed row is 72 pt and a plain row 48 pt at the default text size, and both grow with it")
    func heights() {
        let larger = UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)

        #expect(FileInfoRowModel.height(for: .boxed, compatibleWith: defaultSize) == 72)
        #expect(FileInfoRowModel.height(for: .plain, compatibleWith: defaultSize) == 48)
        #expect(FileInfoRowModel.height(for: .boxed, compatibleWith: larger) > 72)
        #expect(FileInfoRowModel.height(for: .plain, compatibleWith: larger) > 48)
        #expect(FileInfoRowModel.rowSpacing(for: .boxed) == 16)
        #expect(FileInfoRowModel.rowSpacing(for: .plain) == 24)
    }

    @Test("A hosted row is as tall as its model says", arguments: Style.allCases)
    func hostedRowMatchesTheModelHeight(style: Style) {
        let model = FileInfoRowModel(kind: .name, value: "August_Hike_003", style: style)
        // Measured outside a window, where no safe area is added to the row.
        let host = UIHostingController(rootView: FileInfoRow(model: model))
        host.loadViewIfNeeded()

        let fitted = host.sizeThatFits(in: CGSize(width: 342, height: 1000)).height
        let expected = FileInfoRowModel.height(for: style, compatibleWith: host.traitCollection)

        #expect(abs(fitted - expected) <= 1, "fitted \(fitted), model \(expected)")
    }
}
