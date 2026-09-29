//
//  FileCollectionViewHeaderCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.03.2023.
//

import UIKit

class FileCollectionViewHeaderCell: UICollectionReusableView {
    static let identifier = "FileCollectionViewHeaderCell"
    /// As tall as its 40pt buttons.
    static let height: CGFloat = 40
    /// Every icon is drawn centred on a square this size, so each button's insets and padding stay the same.
    static let iconBox = CGSize(width: 24, height: 24)
    static let sortIcon = drawSortIcon(.regular)
    static let selectIcon = drawSelectIcon(.regular)
    /// The icons with Bold Text on.
    static let boldSortIcon = drawSortIcon(.semibold)
    static let boldSelectIcon = drawSelectIcon(.semibold)
    /// The sort button's gap before Clear or Select when it fills the row.
    static let sortGap: CGFloat = 16

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    /// Clear and Select; a hidden one takes no space.
    @IBOutlet weak var trailingButtons: UIStackView!
    
    var leftButtonAction: ((UICollectionReusableView) -> Void)?
    var rightButtonAction: ((UICollectionReusableView) -> Void)?
    var clearButtonAction: ((UICollectionReusableView) -> Void)?
    
    var leftButtonTitle: String? {
        didSet {
            leftButton.configuration?.title = leftButtonTitle
            if sortMenu != nil { applySortSpeech() }
        }
    }
    
    var rightButtonTitle: String? {
        didSet {
            rightButton.configuration?.title = rightButtonTitle
            fitRightButtonToContent()
        }
    }
    
    /// Opens from a tap on the left button. The same menu again is ignored, so a reload that gives this view back
    /// to the synced section leaves an open menu alone.
    var sortMenu: UIMenu? {
        didSet {
            if sortMenu !== oldValue { applySortMenu() }
        }
    }

    /// The list's side inset. The pinned row spans the list's full width, so its buttons move in by this much and
    /// the row turns opaque over the rows passing under it.
    var gutterWidth: CGFloat = 0 {
        didSet {
            if gutterWidth != oldValue { applyGutter() }
        }
    }

    private var nibMargins = NSDirectionalEdgeInsets.zero
    private lazy var sortFillsTheRow = leftButton.trailingAnchor.constraint(equalTo: trailingButtons.leadingAnchor, constant: -Self.sortGap)

    override func awakeFromNib() {
        super.awakeFromNib()
        // With the list's 6pt side inset, the buttons' edges sit 12pt from the screen's.
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
        nibMargins = directionalLayoutMargins
        
        leftButton.configuration = Self.buttonConfiguration(color: UIColor(resource: .blue400))
        leftButton.contentHorizontalAlignment = .leading
        leftButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // On the synced row the sort button, not Select or Clear, takes the spare width.
        leftButton.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        
        var clear = Self.buttonConfiguration(color: .paleRed)
        clear.title = "Clear".localized()
        clearButton.configuration = clear
        clearButton.isHidden = true
        clearButton.accessibilityIdentifier = "headerClearSelectionButton"
        
        var select = Self.buttonConfiguration(color: .darkBlue)
        select.imagePlacement = .trailing
        rightButton.configuration = select
        rightButton.accessibilityIdentifier = "headerSelectButton"
        fitRightButtonToContent()
        
        applySortMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(boldTextChanged), name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
    }

    /// The layout hides the pinned row at alpha 0; VoiceOver then skips it too.
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        accessibilityElementsHidden = layoutAttributes.alpha == 0
    }
    
    func configure(with viewModel: FilesViewModel?, isPickingProfilePicture: Bool = false) {
        guard let viewModel = viewModel else {
            rightButtonTitle = nil
            rightButton.configuration?.image = nil
            clearButton.isHidden = true
            fitRightButtonToContent()
            return
        }
        rightButtonTitle = viewModel.isSelecting ? "Select all".localized() : nil
        rightButton.configuration?.image = viewModel.isSelecting ? Self.checkbox(for: viewModel.checkboxState) : nil
        clearButton.isHidden = !viewModel.isSelecting
        
        if isPickingProfilePicture {
            rightButton.isHidden = true
            clearButton.isHidden = true
        }
        fitRightButtonToContent()
    }

    /// The circled check beside an idle "Select".
    func showSelectIcon() {
        rightButton.configuration?.image = currentSelectIcon
        fitRightButtonToContent()
    }
    
    /// Fades from what the header last showed on screen to what it shows now. Call it right after the change.
    func fadeInChange() {
        let fade = CATransition()
        fade.type = .fade
        fade.duration = 0.25
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(fade, forKey: kCATransition)
    }

    @IBAction func leftButtonPressed(_ sender: Any) {
        leftButtonAction?(self)
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        clearButtonAction?(self)
    }
    
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    // MARK: - Looks

    /// 8pt around a 24pt icon and a 16pt title line. The title keeps its fixed size, not Dynamic Type.
    private static let contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

    private static func buttonConfiguration(color: UIColor) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = contentInsets
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 6
        configuration.imagePadding = 4
        configuration.baseForegroundColor = color
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleAlignment = .leading
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = titleFont
            outgoing.merge(AttributeContainer([.paragraphStyle: titleParagraph()]))
            return outgoing
        }
        return configuration
    }

    private static let titleFont = TextFontStyle.smallRegular.font

    private static func titleParagraph() -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = TextFontStyle.smallRegularLineHeight
        paragraph.maximumLineHeight = TextFontStyle.smallRegularLineHeight
        paragraph.lineBreakMode = .byTruncatingTail
        return paragraph
    }

    private static func symbolSize(_ pointSize: CGFloat, _ weight: UIImage.SymbolWeight) -> UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight, scale: .medium)
    }

    private static func drawSortIcon(_ weight: UIImage.SymbolWeight) -> UIImage? {
        boxed(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: symbolSize(13.75, weight)), mirrored: true)
    }

    private static func drawSelectIcon(_ weight: UIImage.SymbolWeight) -> UIImage? {
        boxed(UIImage(systemName: "checkmark.circle", withConfiguration: symbolSize(16, weight)))
    }

    private var currentSortIcon: UIImage? { UIAccessibility.isBoldTextEnabled ? Self.boldSortIcon : Self.sortIcon }
    private var currentSelectIcon: UIImage? { UIAccessibility.isBoldTextEnabled ? Self.boldSelectIcon : Self.selectIcon }

    /// `image` centred on the 24pt icon square, snapped to whole pixels, as a template; `mirrored` flips it left to right.
    static func boxed(_ image: UIImage?, mirrored: Bool = false) -> UIImage? {
        guard let image else { return nil }
        let format = UIGraphicsImageRendererFormat.preferred()
        let snap = { (value: CGFloat) in (value * format.scale).rounded() / format.scale }
        let origin = CGPoint(x: snap((iconBox.width - image.size.width) / 2), y: snap((iconBox.height - image.size.height) / 2))
        let drawn = UIGraphicsImageRenderer(size: iconBox, format: format).image { context in
            if mirrored {
                context.cgContext.translateBy(x: iconBox.width, y: 0)
                context.cgContext.scaleBy(x: -1, y: 1)
            }
            image.draw(in: CGRect(origin: origin, size: image.size))
        }
        return drawn.withRenderingMode(.alwaysTemplate)
    }

    private static let checkboxes: [CheckboxState: UIImage] = [
        .none: boxed(UIImage(named: "checkBoxEmpty")),
        .partial: boxed(UIImage(named: "checkboxPartial")),
        .selected: boxed(UIImage(named: "checkBoxCheckedFill"))
    ].compactMapValues { $0 }

    private static func checkbox(for state: CheckboxState) -> UIImage? {
        checkboxes[state]
    }

    private func applySortMenu() {
        let hasMenu = sortMenu != nil
        leftButton.menu = sortMenu
        leftButton.showsMenuAsPrimaryAction = hasMenu
        leftButton.preferredMenuElementOrder = .fixed
        leftButton.configuration?.image = hasMenu ? currentSortIcon : nil
        // Only the synced row's sort button reaches across to Clear or Select; other rows keep their title's width.
        sortFillsTheRow.isActive = hasMenu
        leftButton.accessibilityIdentifier = hasMenu ? "folderSortButton" : "headerSortButton"
        leftButton.accessibilityLabel = hasMenu ? String.sortBy : nil
        applySortSpeech()
    }

    /// VoiceOver reads the title with a pause for its mark. Voice Control also answers to the title or its field.
    private func applySortSpeech() {
        guard sortMenu != nil else {
            leftButton.accessibilityValue = nil
            leftButton.accessibilityUserInputLabels = nil
            return
        }
        let title = leftButtonTitle ?? ""
        let field = title.components(separatedBy: SortOption.titleSeparator)[0]
        leftButton.accessibilityValue = leftButtonTitle.map(SortOption.spoken)
        leftButton.accessibilityUserInputLabels = [String.sortBy, SortOption.spoken(title), field].filter { !$0.isEmpty }.uniqued()
    }

    /// The drawn icons do not follow Bold Text by themselves; a select-mode checkbox is left alone.
    @objc private func boldTextChanged() {
        if sortMenu != nil { leftButton.configuration?.image = currentSortIcon }
        let image = rightButton.configuration?.image
        if image != nil, image === Self.selectIcon || image === Self.boldSelectIcon { showSelectIcon() }
    }

    /// A right button with no title and no image takes no width, so it cannot be tapped, and VoiceOver skips it.
    /// With Clear hidden too, the sort button then runs to the row's edge.
    private func fitRightButtonToContent() {
        guard var configuration = rightButton.configuration else { return }
        let isEmpty = (configuration.title ?? "").isEmpty && configuration.image == nil
        configuration.contentInsets = isEmpty ? .zero : Self.contentInsets
        rightButton.configuration = configuration
        rightButton.isAccessibilityElement = !isEmpty
        sortFillsTheRow.constant = isEmpty && clearButton.isHidden ? 0 : -Self.sortGap
    }

    private func applyGutter() {
        var margins = nibMargins
        margins.leading += gutterWidth
        margins.trailing += gutterWidth
        directionalLayoutMargins = margins
        backgroundColor = gutterWidth > 0 ? .systemBackground : nil
    }
}
