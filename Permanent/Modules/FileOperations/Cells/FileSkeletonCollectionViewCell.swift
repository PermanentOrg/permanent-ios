//
//  FileSkeletonCollectionViewCell.swift
//  Permanent
//

import UIKit

/// A placeholder row, or grid tile, for a folder item that has not loaded yet.
class FileSkeletonCollectionViewCell: UICollectionViewCell {
    static let identifier = "FileSkeletonCollectionViewCell"

    private let thumbnailView = UIView()
    private let titleBar = UIView()
    private let subtitleBar = UIView()
    private let shimmerLayer = CAGradientLayer()
    private let shimmerMask = CAShapeLayer()
    private var activeConstraints: [NSLayoutConstraint] = []
    private var isGrid: Bool?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        accessibilityTraits = [.staticText, .updatesFrequently]

        for placeholder in [thumbnailView, titleBar, subtitleBar] {
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            placeholder.backgroundColor = UIColor(.blue50)
            placeholder.layer.cornerCurve = .continuous
            contentView.addSubview(placeholder)
        }
        thumbnailView.layer.cornerRadius = 6
        titleBar.layer.cornerRadius = 4
        subtitleBar.layer.cornerRadius = 4

        shimmerLayer.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.55).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.mask = shimmerMask
        contentView.layer.addSublayer(shimmerLayer)
        contentView.layer.masksToBounds = true

        configure(isGrid: false, accessibilityLabel: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateShimmer), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
    }

    /// A non-nil `accessibilityLabel` makes this placeholder the one VoiceOver reads; the others stay silent.
    func configure(isGrid: Bool, accessibilityLabel: String?) {
        self.accessibilityLabel = accessibilityLabel
        isAccessibilityElement = accessibilityLabel != nil
        accessibilityElementsHidden = accessibilityLabel == nil
        updateShimmer()
        guard isGrid != self.isGrid else { return }
        self.isGrid = isGrid
        NSLayoutConstraint.deactivate(activeConstraints)
        subtitleBar.isHidden = isGrid

        if isGrid {
            // Matches FileCollectionViewGridCell: an edge-to-edge square picture over the name line.
            activeConstraints = [
                thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor),
                thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                thumbnailView.heightAnchor.constraint(equalTo: thumbnailView.widthAnchor),
                titleBar.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 4),
                titleBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                titleBar.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6),
                titleBar.heightAnchor.constraint(equalToConstant: 14)
            ]
        } else {
            // Matches FileCollectionViewCell: a 38pt picture 14pt in, the name and date lines 10pt after it.
            activeConstraints = [
                thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
                thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
                thumbnailView.widthAnchor.constraint(equalToConstant: 38),
                thumbnailView.heightAnchor.constraint(equalToConstant: 38),
                titleBar.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 10),
                titleBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
                titleBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
                titleBar.heightAnchor.constraint(equalToConstant: 15),
                subtitleBar.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor),
                subtitleBar.widthAnchor.constraint(equalTo: titleBar.widthAnchor, multiplier: 0.6),
                subtitleBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 42),
                subtitleBar.heightAnchor.constraint(equalToConstant: 11)
            ]
        }
        NSLayoutConstraint.activate(activeConstraints)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = contentView.bounds
        // The sweep lights the placeholders only, not the row behind them.
        contentView.layoutIfNeeded()
        let shapes = UIBezierPath()
        for placeholder in [thumbnailView, titleBar, subtitleBar] where !placeholder.isHidden {
            shapes.append(UIBezierPath(roundedRect: placeholder.frame, cornerRadius: placeholder.layer.cornerRadius))
        }
        shimmerMask.path = shapes.cgPath
        updateShimmer()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmer()
    }

    /// Still under Reduce Motion, and re-added when missing, since reuse or a trip to the background can drop it.
    @objc private func updateShimmer() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            shimmerLayer.removeAnimation(forKey: "shimmer")
            shimmerLayer.isHidden = true
            return
        }
        shimmerLayer.isHidden = false
        guard window != nil, shimmerLayer.animation(forKey: "shimmer") == nil else { return }
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.4
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        shimmerLayer.add(animation, forKey: "shimmer")
    }
}
