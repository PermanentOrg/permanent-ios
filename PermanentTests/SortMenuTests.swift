//
//  SortMenuTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import XCTest
@testable import Permanent

final class SortMenuTests: XCTestCase {
    private func groups(for current: SortOption, onSelect: @escaping (SortOption) -> Void = { _ in }) -> [UIMenu] {
        let elements = SortMenu.elements(for: current, onSelect: onSelect)
        let menus = elements.compactMap { $0 as? UIMenu }
        XCTAssertEqual(menus.count, elements.count, "every top-level element is a group")
        return menus
    }

    private func actions(in menu: UIMenu) -> [UIAction] {
        let actions = menu.children.compactMap { $0 as? UIAction }
        XCTAssertEqual(actions.count, menu.children.count, "every item in a group is an action")
        return actions
    }

    /// UIKit keeps an action's handler under the "handler" key; there is no public way to fire one.
    private func perform(_ action: UIAction) throws {
        guard action.responds(to: NSSelectorFromString("handler")) else {
            throw XCTSkip("UIAction no longer exposes its handler")
        }
        typealias Handler = @convention(block) (UIAction) -> Void
        let handler = try XCTUnwrap(action.value(forKey: "handler"))
        unsafeBitCast(handler as AnyObject, to: Handler.self)(action)
    }

    /// Which rows carry the drawn checkmark, as VoiceOver hears them.
    private func checked(in menu: UIMenu) -> [Bool] {
        actions(in: menu).map { $0.accessibilityTraits.contains(.selected) }
    }

    private func picks(_ title: String, inGroup index: Int, current: SortOption) throws -> [SortOption] {
        var picked: [SortOption] = []
        let group = groups(for: current) { picked.append($0) }[index]
        try perform(XCTUnwrap(actions(in: group).first { $0.title == title }))
        return picked
    }

    // MARK: - Groups

    func testElements_AreThreeInlineGroups() {
        let groups = groups(for: .dateDescending)
        XCTAssertEqual(groups.count, 3)
        XCTAssertTrue(groups.allSatisfy { $0.options.contains(.displayInline) })
    }

    func testFirstGroup_IsOneSortByLineNamingTheCurrentSort() throws {
        let summary = try XCTUnwrap(actions(in: groups(for: .dateDescending)[0]).first)
        XCTAssertEqual(groups(for: .dateDescending)[0].children.count, 1)
        XCTAssertEqual(summary.title, "Sort by")
        XCTAssertEqual(summary.subtitle, "Date  •  Newest first")
        XCTAssertTrue(summary.attributes.contains(.keepsMenuPresented))
        XCTAssertFalse(summary.attributes.contains(.disabled), "a disabled line would be dimmed")
        XCTAssertEqual(summary.accessibilityLabel, "Sort by, Date, Newest first", "read as the header button reads it")
        XCTAssertNotNil(summary.image, "the arrows sit in the checkmarks' column")
        XCTAssertFalse(checked(in: groups(for: .dateDescending)[0]).contains(true), "the line is not a choice")
    }

    /// Each pixel's opacity, 0 to 255, row by row.
    private func alphas(of image: UIImage) -> (width: Int, values: [UInt8]) {
        guard let cgImage = image.cgImage else { return (0, []) }
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (width, stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] })
    }

    /// The menu ignores a flipped orientation, so the icon has to be mirrored in its pixels.
    func testTheSortByIcon_IsTheUpDownArrowsMirroredInItsPixels_SoTheDownArrowComesFirst() throws {
        let summary = try XCTUnwrap(actions(in: groups(for: .dateDescending)[0]).first)
        let icon = try XCTUnwrap(summary.image)
        let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory))
        let weight: UIImage.SymbolWeight = UIAccessibility.isBoldTextEnabled ? .semibold : .regular
        let symbol = try XCTUnwrap(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: body.pointSize, weight: weight)))
        let plain = alphas(of: UIGraphicsImageRenderer(size: symbol.size).image { _ in symbol.draw(in: CGRect(origin: .zero, size: symbol.size)) })
        let drawn = alphas(of: icon)

        // iOS 27 can round the two sizes a few billionths of a point apart.
        XCTAssertEqual(icon.size.width, symbol.size.width, accuracy: 0.001, "the symbol's own width at the current text size")
        XCTAssertEqual(icon.size.height, symbol.size.height, accuracy: 0.001, "the symbol's own height at the current text size")
        XCTAssertEqual(icon.renderingMode, .alwaysTemplate, "tinted like the menu's text")
        XCTAssertEqual(icon.imageOrientation, .up, "no orientation flag for the menu to drop")
        XCTAssertEqual(drawn.values.count, plain.values.count)
        func difference(_ pixel: (Int, Int) -> Int) -> Double {
            let rows = drawn.values.count / drawn.width
            var total = 0
            for y in 0..<rows {
                for x in 0..<drawn.width { total += abs(Int(drawn.values[y * drawn.width + x]) - pixel(x, y)) }
            }
            return Double(total) / Double(drawn.values.count * 255)
        }
        let mirrored = difference { x, y in Int(plain.values[y * plain.width + (plain.width - 1 - x)]) }
        let asIs = difference { x, y in Int(plain.values[y * plain.width + x]) }
        XCTAssertLessThan(mirrored, 0.01, "the symbol turned left to right")
        XCTAssertGreaterThan(asIs, mirrored * 5, "not the up-first symbol")
    }

    func testSecondGroup_ListsTheFieldsWithTheCurrentOneChecked() {
        let fields = groups(for: .dateDescending)[1]
        XCTAssertEqual(actions(in: fields).map(\.title), ["Name", "Date", "Type"])
        XCTAssertEqual(checked(in: fields), [false, true, false])
        XCTAssertTrue(actions(in: fields).allSatisfy { $0.state == .off }, "a checkmark iOS draws itself pushes the Sort by line right")
        XCTAssertEqual(Set(actions(in: fields).compactMap { $0.image?.size.width }).count, 1, "every title starts at the same place")
    }

    func testThirdGroup_ListsTheDateOrdersWithTheCurrentOneChecked() {
        let orders = groups(for: .dateDescending)[2]
        XCTAssertEqual(actions(in: orders).map(\.title), ["Newest first", "Oldest first"])
        XCTAssertEqual(checked(in: orders), [true, false])
        XCTAssertTrue(actions(in: orders).allSatisfy { $0.state == .off && $0.image != nil })
    }

    func testNameDescending_ListsTheNameOrdersWithZToAChecked() {
        let groups = groups(for: .nameDescending)
        XCTAssertEqual(checked(in: groups[1]), [true, false, false])
        XCTAssertEqual(actions(in: groups[2]).map(\.title), ["A → Z", "Z → A"])
        XCTAssertEqual(actions(in: groups[2]).map(\.accessibilityLabel), ["A to Z", "Z to A"], "VoiceOver says the arrow as a word")
        XCTAssertEqual(checked(in: groups[2]), [false, true])
    }

    func testTypeAscending_ListsTheTypeOrdersWithAscendingChecked() {
        let groups = groups(for: .typeAscending)
        XCTAssertEqual(checked(in: groups[1]), [false, false, true])
        XCTAssertEqual(actions(in: groups[2]).map(\.title), ["Ascending", "Descending"])
        XCTAssertEqual(checked(in: groups[2]), [true, false])
    }

    // MARK: - Picking a field

    func testPickingAnotherField_StartsAtItsFirstOrder() {
        XCTAssertEqual(SortMenu.sort(pickingField: .dateAscending, current: .nameAscending), .dateDescending)
        XCTAssertEqual(SortMenu.sort(pickingField: .typeDescending, current: .nameAscending), .typeAscending)
        XCTAssertEqual(SortMenu.sort(pickingField: .nameDescending, current: .dateAscending), .nameAscending)
    }

    func testPickingTheFieldInUse_GivesNothing() {
        for current in SortOption.allCases {
            for field in current.fieldOrders {
                XCTAssertNil(SortMenu.sort(pickingField: field, current: current), "\(field) while sorted by \(current)")
            }
        }
    }

    // MARK: - Picking an order

    func testPickingTheOtherOrder_GivesIt() throws {
        for current in SortOption.allCases {
            let other = try XCTUnwrap(current.fieldOrders.first { $0 != current })
            XCTAssertEqual(SortMenu.sort(pickingOrder: other, current: current), other, "while sorted by \(current)")
        }
    }

    func testPickingTheOrderInForce_GivesNothing() {
        for current in SortOption.allCases {
            XCTAssertNil(SortMenu.sort(pickingOrder: current, current: current), "\(current)")
        }
    }

    // MARK: - Handlers

    func testTappingAnotherField_SelectsItsFirstOrder() throws {
        let date = try picks("Date", inGroup: 1, current: .nameAscending)
        let type = try picks("Type", inGroup: 1, current: .nameAscending)
        XCTAssertEqual(date, [.dateDescending])
        XCTAssertEqual(type, [.typeAscending])
    }

    func testTappingAnotherOrder_SelectsIt() throws {
        let picked = try picks("Oldest first", inGroup: 2, current: .dateDescending)
        XCTAssertEqual(picked, [.dateAscending])
    }

    func testTappingACheckedItem_SelectsNothing() throws {
        let field = try picks("Date", inGroup: 1, current: .dateDescending)
        let order = try picks("Newest first", inGroup: 2, current: .dateDescending)
        let summary = try picks("Sort by", inGroup: 0, current: .dateDescending)
        XCTAssertEqual(field, [])
        XCTAssertEqual(order, [])
        XCTAssertEqual(summary, [])
    }

    // MARK: - Menu

    func testMake_HoldsOneDeferredElement() {
        let menu = SortMenu.make(current: { .nameAscending }, onSelect: { _ in })
        XCTAssertEqual(menu.children.count, 1)
        XCTAssertTrue(menu.children.first is UIDeferredMenuElement)
    }

    func testEachOpening_ShowsTheSortInForceThen() throws {
        var inForce = SortOption.nameAscending
        let opening = SortMenu.itemsOnOpening(current: { inForce }, onSelect: { _ in })

        let first = try XCTUnwrap(opening() as? [UIMenu])
        inForce = .dateAscending
        let second = try XCTUnwrap(opening() as? [UIMenu])

        XCTAssertEqual(actions(in: first[0]).first?.subtitle, "Name  •  A → Z")
        XCTAssertEqual(checked(in: first[1]), [true, false, false])
        XCTAssertEqual(actions(in: second[0]).first?.subtitle, "Date  •  Oldest first")
        XCTAssertEqual(checked(in: second[1]), [false, true, false])
        XCTAssertEqual(actions(in: second[2]).map(\.title), ["Newest first", "Oldest first"])
        XCTAssertEqual(checked(in: second[2]), [false, true])
    }
}
