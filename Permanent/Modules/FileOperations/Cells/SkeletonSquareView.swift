//
//  SkeletonSquareView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.10.2026.
//

import UIKit

/// The skeleton rows' picture square, for a file row whose picture has not arrived. Its band spans the whole row,
/// so it crosses the square at the skeleton rows' pace.
final class SkeletonSquareView: UIView {
    /// The skeleton shapes' colour, and the picture square's corner radius, for the skeleton rows too.
    static let fill = UIColor(.blue50)
    static let cornerRadius: CGFloat = 6

    private(set) lazy var shimmer = SkeletonShimmer(in: self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = Self.fill
        layer.cornerRadius = Self.cornerRadius
        layer.cornerCurve = .continuous
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        _ = shimmer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rowWidth = superview?.bounds.width ?? bounds.width
        shimmer.layout(lighting: UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius),
                       across: CGRect(x: -frame.minX, y: 0, width: rowWidth, height: bounds.height))
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        shimmer.update()
    }
}
