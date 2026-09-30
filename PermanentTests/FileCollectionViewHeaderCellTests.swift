//
//  FileCollectionViewHeaderCellTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import XCTest
@testable import Permanent

final class FileCollectionViewHeaderCellTests: XCTestCase {
    private static let header = UICollectionView.elementKindSectionHeader
    private static let uploadsPath = IndexPath(item: 0, section: 1)
    private static let syncedPath = IndexPath(item: 0, section: 2)

    /// A header from the nib, as wide as a 390pt list's content between its 6pt side insets.
    private func makeHeader(width: CGFloat = 378) -> FileCollectionViewHeaderCell {
        let header = FileCollectionViewHeaderCell.nib().instantiate(withOwner: nil).first as! FileCollectionViewHeaderCell
        header.frame = CGRect(x: 0, y: 0, width: width, height: FileCollectionViewHeaderCell.height)
        return header
    }

    private func layOut(_ header: FileCollectionViewHeaderCell) {
        header.setNeedsLayout()
        header.layoutIfNeeded()
    }

    private func selecting(_ state: CheckboxState) -> FilesViewModel {
        let viewModel = MyFilesViewModel()
        viewModel.isSelecting = true
        viewModel.checkboxState = state
        return viewModel
    }

    private func attributes(alpha: CGFloat) -> UICollectionViewLayoutAttributes {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.header, with: Self.syncedPath)
        attributes.frame = CGRect(x: 0, y: 0, width: 390, height: FileCollectionViewHeaderCell.height)
        attributes.alpha = alpha
        return attributes
    }

    // MARK: - Looks

    private func hex(_ color: UIColor?) -> String? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let color, color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    /// The box, in points, of the pixels in `image` that are at least 10% opaque.
    private func inkBox(of image: UIImage, in region: CGRect? = nil) -> CGRect {
        guard let cgImage = image.cgImage else { return .null }
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let scale = image.scale
        let area = region.map { CGRect(x: $0.minX * scale, y: $0.minY * scale, width: $0.width * scale, height: $0.height * scale) }
        var box = CGRect.null
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 25 {
                let pixel = CGRect(x: x, y: y, width: 1, height: 1)
                if let area, !area.contains(pixel) { continue }
                box = box.union(pixel)
            }
        }
        return CGRect(x: box.minX / scale, y: box.minY / scale, width: box.width / scale, height: box.height / scale)
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

    private func snapshot(_ header: FileCollectionViewHeaderCell) -> UIImage {
        UIGraphicsImageRenderer(bounds: header.bounds).image { header.layer.render(in: $0.cgContext) }
    }

    func testTheHeaderRow_IsFortyPointsTall() {
        XCTAssertEqual(FileCollectionViewHeaderCell.height, 40)
    }

    func testEveryButton_UsesUsualRegularTwelve_OnASixteenPointLine_WithNoLetterSpacing() throws {
        let header = makeHeader()
        header.leftButtonTitle = "Uploads"
        header.configure(with: selecting(.none))
        layOut(header)

        XCTAssertEqual(TextFontStyle.smallRegular.font.fontName, "Usual-Regular")
        XCTAssertEqual(TextFontStyle.smallRegular.font.pointSize, 12)
        XCTAssertEqual(TextFontStyle.smallRegularLineHeight, 16)
        for button in [header.leftButton!, header.rightButton!, header.clearButton!] {
            let label = try XCTUnwrap(button.titleLabel, "\(button.accessibilityIdentifier ?? "")")
            XCTAssertEqual(label.font.fontName, "Usual-Regular")
            XCTAssertEqual(label.font.pointSize, 12)
            XCTAssertEqual(label.frame.height, 16, accuracy: 0.01, "one 16pt line")
            XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
            let text = try XCTUnwrap(label.attributedText)
            let kern = text.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat
            XCTAssertEqual(kern ?? 0, 0)
            let paragraph = try XCTUnwrap(text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
            XCTAssertEqual(paragraph.minimumLineHeight, 16)
            XCTAssertEqual(paragraph.maximumLineHeight, 16)
        }
    }

    func testTheSortSide_IsBlue400_Select_IsDarkBlue_AndClear_StaysRed() {
        let header = makeHeader()

        XCTAssertEqual(hex(header.leftButton.configuration?.baseForegroundColor), "#898DA4")
        XCTAssertEqual(hex(header.rightButton.configuration?.baseForegroundColor), "#131B4A")
        XCTAssertEqual(header.rightButton.configuration?.baseForegroundColor, .darkBlue)
        XCTAssertEqual(header.clearButton.configuration?.baseForegroundColor, .paleRed)
        XCTAssertEqual(header.clearButton.configuration?.title, "Clear")
    }

    func testEveryButton_HasEightPointInsets_ASixPointRadius_AndFourPointsBeforeAnIcon() {
        let header = makeHeader()
        header.rightButtonTitle = "Select"
        for button in [header.leftButton!, header.rightButton!, header.clearButton!] {
            XCTAssertEqual(button.configuration?.contentInsets, NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            XCTAssertEqual(button.configuration?.imagePadding, 4)
            XCTAssertEqual(button.configuration?.cornerStyle, .fixed)
            XCTAssertEqual(button.configuration?.background.cornerRadius, 6)
            XCTAssertEqual(button.configuration?.background.backgroundColor?.cgColor.alpha ?? 0, 0, "no fill")
        }
    }

    func testTheIcons_AreTwentyFourPointTemplateSquares_HoldingASixteenPointGlyph() throws {
        let icons = [("sort", FileCollectionViewHeaderCell.sortIcon), ("select", FileCollectionViewHeaderCell.selectIcon)]
        for (name, icon) in icons {
            let image = try XCTUnwrap(icon, name)
            XCTAssertEqual(image.size, CGSize(width: 24, height: 24), name)
            XCTAssertEqual(image.renderingMode, .alwaysTemplate, name)
            let ink = inkBox(of: image)
            XCTAssertEqual(max(ink.width, ink.height), 16, accuracy: 0.75, "\(name) glyph \(ink)")
            XCTAssertEqual(ink.midX, 12, accuracy: 0.5, "\(name) centred across")
            XCTAssertEqual(ink.midY, 12, accuracy: 0.5, "\(name) centred down")
        }
    }

    func testTheSortIcon_IsTheUpDownArrowsMirrored_SoTheDownArrowComesFirst() throws {
        let plainSymbol = UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13.75, weight: .regular, scale: .medium))
        let plain = alphas(of: try XCTUnwrap(FileCollectionViewHeaderCell.boxed(plainSymbol)))
        let sort = alphas(of: try XCTUnwrap(FileCollectionViewHeaderCell.sortIcon))
        XCTAssertEqual(plain.values.count, sort.values.count)

        func difference(_ pixel: (Int, Int) -> Int) -> Double {
            let rows = sort.values.count / sort.width
            var total = 0
            for y in 0..<rows {
                for x in 0..<sort.width { total += abs(Int(sort.values[y * sort.width + x]) - pixel(x, y)) }
            }
            return Double(total) / Double(sort.values.count * 255)
        }
        let asDrawn = difference { x, y in Int(plain.values[y * plain.width + x]) }
        let mirrored = difference { x, y in Int(plain.values[y * plain.width + (plain.width - 1 - x)]) }
        XCTAssertLessThan(mirrored, 0.01, "the plain glyph turned left to right")
        XCTAssertGreaterThan(asDrawn, mirrored * 5, "not the plain glyph")
    }

    func testTheButtons_AreFortyPointsTall_WithTheirIcon_AndCentredInTheRow() throws {
        let header = makeHeader()
        header.leftButtonTitle = SortOption.dateDescending.title
        header.sortMenu = UIMenu(children: [])
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        for button in [header.leftButton!, header.rightButton!] {
            let frame = button.convert(button.bounds, to: header)
            XCTAssertEqual(frame.height, 40, accuracy: 0.01)
            XCTAssertEqual(frame.minY, 0, accuracy: 0.01)
            let icon = try XCTUnwrap(button.imageView)
            XCTAssertEqual(icon.bounds.size, CGSize(width: 24, height: 24))
        }
        let sortIcon = try XCTUnwrap(header.leftButton.imageView).frame
        let sortTitle = try XCTUnwrap(header.leftButton.titleLabel).frame
        XCTAssertEqual(sortIcon.minX, 8, accuracy: 0.01)
        XCTAssertEqual(sortTitle.minX - sortIcon.maxX, 4, accuracy: 0.5)
    }

    func testSelect_ShowsItsIconFourPointsAfterTheTitle() throws {
        let header = makeHeader()
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        XCTAssertEqual(header.rightButton.configuration?.imagePlacement, .trailing)
        let title = try XCTUnwrap(header.rightButton.titleLabel)
        let icon = try XCTUnwrap(header.rightButton.imageView)
        let gap = icon.convert(icon.bounds, to: header).minX - title.convert(title.bounds, to: header).maxX
        XCTAssertEqual(gap, 4, accuracy: 0.5)
        XCTAssertEqual(icon.frame.maxX, header.rightButton.bounds.width - 8, accuracy: 0.01)
    }

    func testOnTheSyncedRow_TheSortButtonFillsTheRow_UpToSixteenPointsBeforeSelectOrClear() {
        let header = makeHeader()
        header.leftButtonTitle = SortOption.dateDescending.title
        header.sortMenu = UIMenu(children: [])
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        XCTAssertEqual(header.leftButton.frame.maxX, header.trailingButtons.frame.minX - 16, accuracy: 0.01)
        XCTAssertEqual(header.rightButton.frame.minX, 0, accuracy: 0.01, "a hidden Clear takes no space")
        XCTAssertEqual(header.leftButton.contentHorizontalAlignment, .leading)
        XCTAssertEqual(header.leftButton.titleLabel?.frame.minX ?? 0, 8 + 24 + 4, accuracy: 0.5, "title after the icon, at the left")

        header.configure(with: selecting(.partial))
        header.rightButtonTitle = "Select all"
        layOut(header)

        let clear = header.clearButton.convert(header.clearButton.bounds, to: header)
        XCTAssertEqual(header.leftButton.frame.maxX, clear.minX - 16, accuracy: 0.01, "Clear is the first button on the right")
    }

    func testWithoutAMenu_TheLeftButtonKeepsItsTitlesWidth() {
        let header = makeHeader()
        header.leftButtonTitle = "Uploads"
        header.rightButtonTitle = "Cancel All"
        layOut(header)

        XCTAssertEqual(header.leftButton.frame.width, header.leftButton.intrinsicContentSize.width, accuracy: 0.5)
        XCTAssertLessThan(header.leftButton.frame.maxX, header.trailingButtons.frame.minX - 16)
    }

    func testALongSortTitle_TruncatesBeforeSelect() throws {
        let header = makeHeader(width: 320)
        header.leftButtonTitle = String(repeating: "Newest first ", count: 6)
        header.sortMenu = UIMenu(children: [])
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        XCTAssertEqual(header.leftButton.frame.maxX, header.trailingButtons.frame.minX - 16, accuracy: 0.01)
        XCTAssertEqual(header.rightButton.frame.width, header.rightButton.intrinsicContentSize.width, accuracy: 0.5, "Select is not squeezed")
        let title = try XCTUnwrap(header.leftButton.titleLabel)
        XCTAssertLessThanOrEqual(title.frame.maxX, header.leftButton.bounds.width - 8 + 0.01)
    }

    func testAnEmptySelect_TakesNoWidth_NoTaps_AndNoVoiceOverStop_AndTheSortButtonRunsToTheEdge() {
        let header = makeHeader(width: 390)
        header.gutterWidth = 6
        header.leftButtonTitle = SortOption.dateDescending.title
        header.sortMenu = UIMenu(children: [])
        header.configure(with: MyFilesViewModel())
        layOut(header)

        let select = header.rightButton.convert(header.rightButton.bounds, to: header)
        XCTAssertEqual(select.width, 0, accuracy: 0.01)
        XCTAssertFalse(header.hitTest(CGPoint(x: 372, y: 28), with: nil) === header.rightButton, "the empty right side takes no taps")
        XCTAssertFalse(header.rightButton.isAccessibilityElement)
        XCTAssertEqual(header.leftButton.frame.maxX, 378, accuracy: 0.01, "no gap before an empty right side")

        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        XCTAssertEqual(header.rightButton.configuration?.contentInsets, NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        XCTAssertTrue(header.rightButton.isAccessibilityElement)
        XCTAssertEqual(header.leftButton.frame.maxX, header.trailingButtons.frame.minX - 16, accuracy: 0.01)
    }

    func testWithBoldText_TheIconsHaveHeavierTwins_DrawnTheSameWay() throws {
        for (name, regular, bold) in [("sort", FileCollectionViewHeaderCell.sortIcon, FileCollectionViewHeaderCell.boldSortIcon),
                                      ("select", FileCollectionViewHeaderCell.selectIcon, FileCollectionViewHeaderCell.boldSelectIcon)] {
            let light = try XCTUnwrap(regular, name)
            let heavy = try XCTUnwrap(bold, name)
            XCTAssertEqual(heavy.size, CGSize(width: 24, height: 24), name)
            XCTAssertEqual(heavy.renderingMode, .alwaysTemplate, name)
            let ink = { (image: UIImage) in self.alphas(of: image).values.reduce(0) { $0 + Int($1) } }
            XCTAssertGreaterThan(ink(heavy), ink(light), "\(name): more ink")
            XCTAssertEqual(inkBox(of: heavy).midX, 12, accuracy: 0.75, "\(name) centred across")
        }
        let heavySort = alphas(of: try XCTUnwrap(FileCollectionViewHeaderCell.boldSortIcon))
        let heavyPlain = alphas(of: try XCTUnwrap(FileCollectionViewHeaderCell.boxed(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13.75, weight: .semibold, scale: .medium)))))
        let rows = heavySort.values.count / heavySort.width
        var turned = 0
        for y in 0..<rows {
            for x in 0..<heavySort.width { turned += abs(Int(heavySort.values[y * heavySort.width + x]) - Int(heavyPlain.values[y * heavyPlain.width + (heavyPlain.width - 1 - x)])) }
        }
        XCTAssertLessThan(Double(turned) / Double(heavySort.values.count * 255), 0.01, "the bold sort icon is mirrored too")
    }

    func testABoldTextChange_KeepsTheIconsOfThisSetting_AndLeavesACheckboxAlone() {
        let header = makeHeader()
        header.sortMenu = UIMenu(children: [])
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        let expectedSort = UIAccessibility.isBoldTextEnabled ? FileCollectionViewHeaderCell.boldSortIcon : FileCollectionViewHeaderCell.sortIcon
        let expectedSelect = UIAccessibility.isBoldTextEnabled ? FileCollectionViewHeaderCell.boldSelectIcon : FileCollectionViewHeaderCell.selectIcon

        NotificationCenter.default.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)

        XCTAssertTrue(header.leftButton.configuration?.image === expectedSort)
        XCTAssertTrue(header.rightButton.configuration?.image === expectedSelect)

        header.configure(with: selecting(.partial))
        let checkbox = header.rightButton.configuration?.image
        NotificationCenter.default.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        XCTAssertTrue(header.rightButton.configuration?.image === checkbox, "select mode keeps its checkbox")
    }

    /// The pinned synced row puts its buttons 12pt from each edge and 16pt apart, with the text on its baseline.
    func testThePinnedSyncedRow_SitsTwelvePointsIn_WithSixteenPointsBetweenItsButtons() throws {
        let header = makeHeader(width: 390)
        header.gutterWidth = 6
        header.leftButtonTitle = SortOption.dateDescending.title
        header.sortMenu = UIMenu(children: [])
        header.rightButtonTitle = "Select"
        header.showSelectIcon()
        layOut(header)

        let sortTitle = try XCTUnwrap(header.leftButton.titleLabel)
        let selectTitle = try XCTUnwrap(header.rightButton.titleLabel)
        let select = header.rightButton.convert(header.rightButton.bounds, to: header)
        let sortIcon = try XCTUnwrap(header.leftButton.imageView).convert(header.leftButton.imageView!.bounds, to: header)
        let selectIcon = try XCTUnwrap(header.rightButton.imageView).convert(header.rightButton.imageView!.bounds, to: header)
        let sortText = sortTitle.convert(sortTitle.bounds, to: header)
        let selectText = selectTitle.convert(selectTitle.bounds, to: header)
        header.backgroundColor = nil
        let picture = snapshot(header)
        let sortGlyph = inkBox(of: picture, in: sortIcon)
        let selectGlyph = inkBox(of: picture, in: selectIcon)
        let sortInk = inkBox(of: picture, in: sortText)
        let selectInk = inkBox(of: picture, in: selectText)

        XCTAssertEqual(header.leftButton.frame.minX, 12, accuracy: 0.01)
        XCTAssertEqual(select.maxX, 378, accuracy: 0.01)
        XCTAssertEqual(select.minX - header.leftButton.frame.maxX, 16, accuracy: 0.01)
        XCTAssertEqual(select.width, header.rightButton.intrinsicContentSize.width, accuracy: 0.5, "the sort button, not Select, takes the spare width")
        XCTAssertFalse(header.leftButton.hasAmbiguousLayout)
        XCTAssertFalse(header.rightButton.hasAmbiguousLayout)
        XCTAssertFalse(header.trailingButtons.hasAmbiguousLayout)
        XCTAssertEqual(sortGlyph.minX, 24, accuracy: 1, "the sort glyph starts 24pt from the screen's edge")
        XCTAssertEqual(selectGlyph.maxX, 390 - 24, accuracy: 1, "the Select glyph ends 24pt from the screen's edge")
        XCTAssertEqual(sortText.height, 16, accuracy: 0.01)
        XCTAssertEqual(selectText.height, 16, accuracy: 0.01)
        // The 16pt line puts its spare 1.67pt above the text, so the baseline sits on the line's descender.
        let baseline = 16 + TextFontStyle.smallRegular.font.descender
        XCTAssertEqual(selectInk.maxY - selectText.minY, baseline, accuracy: 0.5)
        XCTAssertEqual(sortInk.maxY - sortText.minY, baseline, accuracy: 0.5)
    }

    // MARK: - Ids

    func testAtRest_TheButtonsKeepTheirIds_AndTheLeftOneHasNoMenu() {
        let header = makeHeader()

        XCTAssertEqual(header.leftButton.accessibilityIdentifier, "headerSortButton")
        XCTAssertEqual(header.rightButton.accessibilityIdentifier, "headerSelectButton")
        XCTAssertEqual(header.clearButton.accessibilityIdentifier, "headerClearSelectionButton")
        XCTAssertNil(header.leftButton.menu)
        XCTAssertFalse(header.leftButton.showsMenuAsPrimaryAction)
        XCTAssertNil(header.leftButton.configuration?.image)
    }

    // MARK: - Sort menu

    func testASortMenu_OpensFromTheLeftButton_AsTheFolderSortButton() {
        let header = makeHeader()
        header.leftButtonTitle = "Date  \u{2022}  Newest first"

        header.sortMenu = UIMenu(title: "probe", children: [])

        XCTAssertEqual(header.leftButton.menu?.title, "probe")
        XCTAssertTrue(header.leftButton.showsMenuAsPrimaryAction)
        XCTAssertEqual(header.leftButton.preferredMenuElementOrder, .fixed)
        XCTAssertEqual(header.leftButton.configuration?.image, FileCollectionViewHeaderCell.sortIcon)
        XCTAssertEqual(header.leftButton.accessibilityIdentifier, "folderSortButton")
        XCTAssertEqual(header.leftButton.accessibilityLabel, "Sort by")
        XCTAssertEqual(header.leftButton.accessibilityValue, "Date, Newest first")
        XCTAssertEqual(header.leftButton.accessibilityUserInputLabels, ["Sort by", "Date, Newest first", "Date"], "Voice Control answers to what it shows")
    }

    func testTheSortValue_FollowsATitleSetAfterTheMenu() {
        let header = makeHeader()
        header.sortMenu = UIMenu(children: [])

        header.leftButtonTitle = SortOption.nameDescending.title

        XCTAssertEqual(header.leftButton.accessibilityValue, "Name, Z to A")
        XCTAssertEqual(header.leftButton.accessibilityUserInputLabels, ["Sort by", "Name, Z to A", "Name"])
        XCTAssertEqual(header.leftButton.configuration?.title, "Name  \u{2022}  Z to A")
    }

    func testNoMenu_RestoresThePlainHeaderSortButton() {
        let header = makeHeader()
        header.leftButtonTitle = "Uploads"
        let plainInputLabels = header.leftButton.accessibilityUserInputLabels
        header.sortMenu = UIMenu(children: [])

        header.sortMenu = nil

        XCTAssertNil(header.leftButton.menu)
        XCTAssertFalse(header.leftButton.showsMenuAsPrimaryAction)
        XCTAssertNil(header.leftButton.configuration?.image)
        XCTAssertEqual(header.leftButton.accessibilityIdentifier, "headerSortButton")
        XCTAssertNotEqual(header.leftButton.accessibilityLabel, "Sort by")
        XCTAssertNil(header.leftButton.accessibilityValue)
        XCTAssertEqual(header.leftButton.accessibilityUserInputLabels, plainInputLabels)
    }

    func testTheSameMenuAgain_LeavesTheButtonAlone_AndANewOneReplacesIt() {
        let header = makeHeader()
        let menu = UIMenu(children: [])
        header.sortMenu = menu
        header.leftButton.accessibilityIdentifier = "untouched"

        header.sortMenu = menu
        XCTAssertEqual(header.leftButton.accessibilityIdentifier, "untouched")

        header.sortMenu = UIMenu(title: "other", children: [])
        XCTAssertEqual(header.leftButton.menu?.title, "other")
        XCTAssertEqual(header.leftButton.accessibilityIdentifier, "folderSortButton")
    }

    // MARK: - Select

    func testTheSelectIcon_IsTheCircledCheck_BesideSelect() {
        let header = makeHeader()
        header.rightButtonTitle = "Select"

        header.showSelectIcon()

        XCTAssertEqual(header.rightButton.configuration?.image, FileCollectionViewHeaderCell.selectIcon)
        XCTAssertEqual(header.rightButton.configuration?.title, "Select")
    }

    func testSelectMode_ShowsTheCheckboxForEachState_AndClear() throws {
        let expected: [(CheckboxState, String)] = [(.none, "checkBoxEmpty"), (.partial, "checkboxPartial"), (.selected, "checkBoxCheckedFill")]
        var drawn: [Data] = []
        for (state, name) in expected {
            let header = makeHeader()
            header.configure(with: selecting(state))

            let image = try XCTUnwrap(header.rightButton.configuration?.image, "\(state)")
            XCTAssertEqual(image.renderingMode, .alwaysTemplate, "\(state)")
            XCTAssertEqual(image.size, CGSize(width: 24, height: 24), "\(state)")
            XCTAssertEqual(image.pngData(), FileCollectionViewHeaderCell.boxed(UIImage(named: name))?.pngData(), "\(state)")
            XCTAssertEqual(header.rightButton.configuration?.title, "Select all")
            XCTAssertFalse(header.clearButton.isHidden, "\(state)")
            drawn.append(try XCTUnwrap(image.pngData()))
        }
        XCTAssertEqual(Set(drawn).count, 3)
    }

    func testLeavingSelectMode_DropsTheCheckboxAndClear() {
        let header = makeHeader()
        header.configure(with: selecting(.selected))

        header.configure(with: MyFilesViewModel())

        XCTAssertNil(header.rightButton.configuration?.image)
        XCTAssertNil(header.rightButton.configuration?.title)
        XCTAssertTrue(header.clearButton.isHidden)
    }

    func testNoViewModel_EmptiesTheRightButton() {
        let header = makeHeader()
        header.configure(with: selecting(.partial))

        header.configure(with: nil)

        XCTAssertNil(header.rightButton.configuration?.image)
        XCTAssertNil(header.rightButtonTitle)
        XCTAssertTrue(header.clearButton.isHidden)
    }

    func testPickingAProfilePicture_HidesSelectAndClear() {
        let header = makeHeader()

        header.configure(with: selecting(.none), isPickingProfilePicture: true)

        XCTAssertTrue(header.rightButton.isHidden)
        XCTAssertTrue(header.clearButton.isHidden)
    }

    // MARK: - Hidden

    func testAtAlphaZero_TheRowLeavesTheAccessibilityTree_AndComesBackWhenShown() {
        let header = makeHeader()

        header.apply(attributes(alpha: 0))
        XCTAssertTrue(header.accessibilityElementsHidden)

        header.apply(attributes(alpha: 1))
        XCTAssertFalse(header.accessibilityElementsHidden)
    }

    // MARK: - Gutter

    func testTheGutter_MovesTheButtonsIn_AndMakesTheRowOpaque() {
        let header = makeHeader(width: 390)
        header.leftButtonTitle = SortOption.nameAscending.title
        header.rightButtonTitle = "Select"
        layOut(header)
        let rightEdge = { header.rightButton.convert(header.rightButton.bounds, to: header).maxX }
        let left = header.leftButton.frame.minX
        let right = rightEdge()

        header.gutterWidth = 6
        layOut(header)

        XCTAssertEqual(header.leftButton.frame.minX, left + 6, accuracy: 0.01)
        XCTAssertEqual(rightEdge(), right - 6, accuracy: 0.01)
        XCTAssertEqual(header.backgroundColor, .systemBackground)

        header.gutterWidth = 0
        layOut(header)

        XCTAssertEqual(header.leftButton.frame.minX, left, accuracy: 0.01)
        XCTAssertEqual(rightEdge(), right, accuracy: 0.01)
        XCTAssertNil(header.backgroundColor)
    }

    // MARK: - In a list

    /// The test list with this nib as its headers, in a window, at the top.
    private func makeHostedList() -> (StickyHeaderTestList, StickyHeaderFlowLayout) {
        let layout = StickyHeaderFlowLayout.fileList()
        let list = StickyHeaderTestList(layout: layout)
        list.uploadsHeaderHeight = FileCollectionViewHeaderCell.height
        list.syncedHeaderHeight = FileCollectionViewHeaderCell.height
        list.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: Self.header, withReuseIdentifier: StickyHeaderTestList.headerId)
        let window = UIWindow(frame: list.frame)
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        list.reloadData()
        list.scroll(to: 0)
        return (list, layout)
    }

    private func headerView(in list: UICollectionView, at path: IndexPath) throws -> FileCollectionViewHeaderCell {
        try XCTUnwrap(list.supplementaryView(forElementKind: Self.header, at: path) as? FileCollectionViewHeaderCell)
    }

    func testInAList_TheFullWidthRowCoversTheGutters_AndLinesItsButtonsUpWithUploads() throws {
        let (list, _) = makeHostedList()
        let uploads = try headerView(in: list, at: Self.uploadsPath)
        let synced = try headerView(in: list, at: Self.syncedPath)
        for header in [uploads, synced] {
            header.leftButtonTitle = "Uploads"
            header.rightButtonTitle = "Cancel All"
        }

        synced.gutterWidth = list.contentInset.left
        list.layoutIfNeeded()
        layOut(uploads)
        layOut(synced)

        XCTAssertEqual(synced.frame.minX, -list.contentInset.left)
        XCTAssertEqual(synced.frame.width, list.bounds.width)
        XCTAssertEqual(synced.backgroundColor, .systemBackground)
        XCTAssertNil(uploads.backgroundColor)
        let uploadsLeft = uploads.leftButton.convert(uploads.leftButton.bounds, to: list)
        let syncedLeft = synced.leftButton.convert(synced.leftButton.bounds, to: list)
        XCTAssertEqual(syncedLeft.minX, uploadsLeft.minX, accuracy: 0.01)
        let uploadsRight = uploads.rightButton.convert(uploads.rightButton.bounds, to: list)
        let syncedRight = synced.rightButton.convert(synced.rightButton.bounds, to: list)
        XCTAssertEqual(syncedRight.maxX, uploadsRight.maxX, accuracy: 0.01)
        let uploadsOnScreen = uploads.leftButton.convert(uploads.leftButton.bounds, to: nil)
        let rightOnScreen = uploads.rightButton.convert(uploads.rightButton.bounds, to: nil)
        XCTAssertEqual(uploadsOnScreen.minX, 12, accuracy: 0.01, "12pt from the screen's left edge")
        XCTAssertEqual(rightOnScreen.maxX, list.bounds.width - 12, accuracy: 0.01, "12pt from the screen's right edge")
    }

    func testInAList_AHiddenRowKeepsItsView_AndLeavesTheAccessibilityTreeUntilShown() throws {
        let (list, layout) = makeHostedList()
        list.scroll(to: 600)

        layout.hidesStickyHeader = true
        list.layoutIfNeeded()

        let hidden = try headerView(in: list, at: Self.syncedPath)
        XCTAssertTrue(list.visibleSupplementaryViews(ofKind: Self.header).contains(hidden))
        XCTAssertEqual(hidden.alpha, 0)
        XCTAssertTrue(hidden.accessibilityElementsHidden)

        layout.hidesStickyHeader = false
        list.layoutIfNeeded()

        let shown = try headerView(in: list, at: Self.syncedPath)
        XCTAssertEqual(shown.alpha, 1)
        XCTAssertFalse(shown.accessibilityElementsHidden)
    }
}
