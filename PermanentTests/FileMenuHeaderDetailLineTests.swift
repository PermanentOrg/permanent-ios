//
//  FileMenuHeaderDetailLineTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 23.11.2026.
//

import SwiftUI
import Testing
import UIKit
@testable import Permanent

@MainActor
struct FileMenuHeaderDetailLineTests {
    /// The text column of the item menu header on a 393pt-wide iPhone 16.
    private static let iPhone16ColumnWidth: CGFloat = 249

    @Test("The size and a date with a time stay on one line", arguments: [
        (width: iPhone16ColumnWidth, date: "Nov. 18, 2026 • 9:00 AM EST"),
        (width: 200, date: "Sept. 30, 2026 • 12:45 PM GMT+5:30")
    ])
    func dateWithTimeStaysOnOneLine(width: CGFloat, date: String) {
        let oneLine = height(of: FileMenuHeaderDetailLine(size: "5.9 MB", date: "Nov. 18, 2026"), width: 400)
        let line = height(of: FileMenuHeaderDetailLine(size: "5.9 MB", date: date), width: width)

        #expect(oneLine > 0)
        #expect(line <= oneLine + 0.5)
    }

    @Test("A folder line shows only the date, also on one line")
    func folderLineWithoutSize() {
        let oneLine = height(of: FileMenuHeaderDetailLine(size: nil, date: "Nov. 18, 2026"), width: 400)
        let line = height(of: FileMenuHeaderDetailLine(size: nil, date: "Nov. 18, 2026 • 9:00 AM EST"),
                          width: Self.iPhone16ColumnWidth)

        #expect(line <= oneLine + 0.5)
    }

    private func height(of line: FileMenuHeaderDetailLine, width: CGFloat) -> CGFloat {
        let host = UIHostingController(rootView: line)
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}
