//
//  SkeletonShimmer.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.10.2026.
//

import UIKit

/// The light sweep over skeleton shapes: a soft white band across the host once every 1.4 s, still under Reduce Motion.
/// The skeleton rows and a file row's picture slot share it, so the two always move alike.
final class SkeletonShimmer {
    /// Off holds the shapes still, as under a failed page's retry footer or for a picture whose download failed.
    var isOn = true {
        didSet { if isOn != oldValue { update() } }
    }

    private let gradient = CAGradientLayer()
    private let mask = CAShapeLayer()
    private weak var host: UIView?
    private let reducesMotion: () -> Bool
    private var observer: NSObjectProtocol?

    private static let animationKey = "shimmer"

    /// Adds the band on top of `host`'s layer.
    init(in host: UIView, reducesMotion: @escaping () -> Bool = { UIAccessibility.isReduceMotionEnabled }) {
        self.host = host
        self.reducesMotion = reducesMotion
        gradient.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.55).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        gradient.mask = mask
        host.layer.addSublayer(gradient)
        observer = NotificationCenter.default.addObserver(forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.update()
        }
    }

    deinit {
        observer.map(NotificationCenter.default.removeObserver)
    }

    var isSweeping: Bool {
        !gradient.isHidden && gradient.animation(forKey: Self.animationKey) != nil
    }

    /// What the band lights, in the host's coordinates.
    var litRect: CGRect {
        guard let box = mask.path?.boundingBox else { return .null }
        return box.offsetBy(dx: gradient.frame.minX, dy: gradient.frame.minY)
    }

    /// The band crosses `span`, the host's bounds unless given, and lights only `shapes`; both in the host's coordinates.
    func layout(lighting shapes: UIBezierPath, across span: CGRect? = nil) {
        guard let host else { return }
        let frame = span ?? host.bounds
        let path = UIBezierPath(cgPath: shapes.cgPath)
        path.apply(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        // Standalone layers animate geometry changes by default; the band must follow the host at once.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = frame
        mask.path = path.cgPath
        CATransaction.commit()
        update()
    }

    /// Starts the band when it is on, on screen and motion is allowed, and stops it otherwise. Reuse or a trip to the
    /// background can drop the animation, so hosts call this again after those.
    func update() {
        guard isOn, !reducesMotion() else {
            gradient.removeAnimation(forKey: Self.animationKey)
            gradient.isHidden = true
            return
        }
        gradient.isHidden = false
        guard host?.window != nil, gradient.animation(forKey: Self.animationKey) == nil else { return }
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.4
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        // One clock for every band, so rows sweep together and a band added again after a reload picks up mid-pass.
        let now = gradient.convertTime(CACurrentMediaTime(), from: nil)
        animation.beginTime = now - now.truncatingRemainder(dividingBy: animation.duration)
        gradient.add(animation, forKey: Self.animationKey)
    }
}
