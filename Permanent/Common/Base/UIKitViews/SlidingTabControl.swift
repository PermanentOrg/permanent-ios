//
//  SlidingTabControl.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.09.2026.
//

import UIKit

/// Tabs on a track, with a pill that slides to the chosen one. Used in place of `UISegmentedControl`,
/// whose pill turns to clear glass while it moves and washes out a custom fill and title colour.
final class SlidingTabControl: UIControl {
    var titles: [String] = [] {
        didSet { rebuildTabs() }
    }

    /// Set in code, the pill moves without an animation or a `valueChanged` event, as in `UISegmentedControl`.
    var selectedSegmentIndex = 0 {
        didSet {
            updateSelectedTraits()
            setNeedsLayout()
        }
    }

    // MARK: - Look

    /// The track is the control's `backgroundColor`.
    var pillColor: UIColor = .primary {
        didSet { pill.backgroundColor = pillColor }
    }
    var titleColor: UIColor = .label {
        didSet { styleTitles() }
    }
    var selectedTitleColor: UIColor = .white {
        didSet { styleTitles() }
    }
    var titleFont: UIFont = TextFontStyle.style8.font {
        didSet { styleTitles() }
    }
    var selectedTitleFont: UIFont = TextFontStyle.style11.font {
        didSet { styleTitles() }
    }
    /// The track's height, which is the control's intrinsic height.
    var trackHeight: CGFloat = 32 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    /// Nil rounds the track, or the pill, to a half circle at each end.
    var trackCornerRadius: CGFloat? {
        didSet { setNeedsLayout() }
    }
    var pillCornerRadius: CGFloat? {
        didSet { setNeedsLayout() }
    }
    /// Shows each title in capitals. VoiceOver and UI tests still read the title as given.
    var uppercasesTitles = false {
        didSet { styleTitles() }
    }
    /// The space added between a title's letters, in points.
    var titleKerning: CGFloat = 0 {
        didSet { styleTitles() }
    }

    private var tabs: [UIButton] = []
    private let pill = UIView()
    /// Copies of the titles in the selected look, cut to the pill's shape, so a title takes that look exactly
    /// where the pill covers it.
    private let selectedTitles = UIView()
    private let selectedTitlesMask = UIView()
    private var selectedLabels: [UILabel] = []

    private static let pillInset: CGFloat = 2
    private static let duration: TimeInterval = 0.3

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = .tertiarySystemFill
        pill.backgroundColor = pillColor
        selectedTitlesMask.backgroundColor = .black
        selectedTitles.mask = selectedTitlesMask
        selectedTitles.accessibilityElementsHidden = true
        // Above the tab buttons, which still take the taps and speak to VoiceOver.
        for overlay in [pill, selectedTitles] {
            overlay.isUserInteractionEnabled = false
            addSubview(overlay)
        }
        // Each title is a button VoiceOver hears as selected or not. A tab-bar trait here would also turn
        // each button's own label into a button, so UI tests would find every tab twice.
        isAccessibilityElement = false
        addInteraction(UILargeContentViewerInteraction())
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: trackHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = trackCornerRadius ?? bounds.height / 2
        selectedTitles.frame = bounds
        let frames = tabFrames
        for (index, frame) in frames.enumerated() {
            tabs[index].frame = frame
            selectedLabels[index].frame = frame
        }
        pill.isHidden = !frames.indices.contains(selectedSegmentIndex)
        guard !pill.isHidden else { return }
        let pillFrame = frames[selectedSegmentIndex].insetBy(dx: Self.pillInset, dy: Self.pillInset)
        for shape in [pill, selectedTitlesMask] {
            shape.frame = pillFrame
            shape.layer.cornerRadius = pillCornerRadius ?? pillFrame.height / 2
        }
    }

    private var tabFrames: [CGRect] {
        guard !tabs.isEmpty else { return [] }
        let width = bounds.width / CGFloat(tabs.count)
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return tabs.indices.map { index in
            let slot = isRightToLeft ? tabs.count - 1 - index : index
            return CGRect(x: CGFloat(slot) * width, y: 0, width: width, height: bounds.height)
        }
    }

    private func rebuildTabs() {
        tabs.forEach { $0.removeFromSuperview() }
        selectedLabels.forEach { $0.removeFromSuperview() }
        tabs = titles.map { title in
            let tab = UIButton(type: .custom)
            tab.setTitle(title, for: .normal)
            tab.titleLabel?.lineBreakMode = .byTruncatingTail
            tab.showsLargeContentViewer = true
            tab.largeContentTitle = title
            tab.addTarget(self, action: #selector(tabReleased(_:event:)), for: [.touchUpInside, .touchUpOutside])
            insertSubview(tab, belowSubview: pill)
            return tab
        }
        selectedLabels = titles.map { title in
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.lineBreakMode = .byTruncatingTail
            selectedTitles.addSubview(label)
            return label
        }
        styleTitles()
        updateSelectedTraits()
        setNeedsLayout()
    }

    /// The plain colour and font stay set beside the attributed title, so a reader of either sees the same look.
    private func styleTitles() {
        for (tab, title) in zip(tabs, titles) {
            tab.setTitleColor(titleColor, for: .normal)
            tab.setTitleColor(titleColor.withAlphaComponent(0.6), for: .highlighted)
            tab.titleLabel?.font = titleFont
            tab.setAttributedTitle(styled(title, font: titleFont, color: titleColor), for: .normal)
            tab.setAttributedTitle(styled(title, font: titleFont, color: titleColor.withAlphaComponent(0.6)), for: .highlighted)
            tab.accessibilityLabel = title
        }
        for (label, title) in zip(selectedLabels, titles) {
            label.textColor = selectedTitleColor
            label.font = selectedTitleFont
            label.attributedText = styled(title, font: selectedTitleFont, color: selectedTitleColor)
        }
    }

    private func styled(_ title: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let shown = uppercasesTitles ? title.uppercased() : title
        return NSAttributedString(string: shown, attributes: [.font: font, .foregroundColor: color, .kern: titleKerning])
    }

    private func updateSelectedTraits() {
        for (index, tab) in tabs.enumerated() {
            tab.accessibilityTraits = index == selectedSegmentIndex ? [.button, .selected] : .button
            // The position a segmented control reads out, such as "1 of 2".
            tab.accessibilityValue = String(format: "TabPosition".localized(), index + 1, tabs.count)
        }
    }

    /// The tab under the lifted finger wins, as in `UISegmentedControl`, even when the press began on the other one.
    @objc private func tabReleased(_ tab: UIButton, event: UIEvent?) {
        // VoiceOver and keyboard activations carry no touch, so they pick the button's own tab.
        guard let point = event?.touches(for: tab)?.first?.location(in: self) else {
            if let index = tabs.firstIndex(of: tab) { userSelected(index) }
            return
        }
        guard bounds.insetBy(dx: 0, dy: -bounds.height).contains(point),
              let index = tabFrames.firstIndex(where: { $0.minX <= point.x && point.x < $0.maxX }) else { return }
        userSelected(index)
    }

    private func userSelected(_ index: Int) {
        guard index != selectedSegmentIndex else { return }
        layoutIfNeeded()
        if UIAccessibility.isReduceMotionEnabled {
            // The pill fades across instead of sliding.
            UIView.transition(with: self, duration: Self.duration, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.selectedSegmentIndex = index
                self.layoutIfNeeded()
            }
        } else {
            selectedSegmentIndex = index
            UIView.animate(withDuration: Self.duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.layoutIfNeeded()
            }
        }
        sendActions(for: .valueChanged)
    }
}
