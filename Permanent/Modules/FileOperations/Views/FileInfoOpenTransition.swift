//
//  FileInfoOpenTransition.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import UIKit

/// Opens the Info screen over the preview: the photo moves into the picture slot while the rest fades in and
/// rises. With no photo on screen, or with Reduce Motion on, the screen only fades in.
final class FileInfoOpenTransition: NSObject, UIViewControllerAnimatedTransitioning {
    static let moveDuration: TimeInterval = 0.35
    static let fadeDuration: TimeInterval = 0.25
    /// How far the screen rises while it fades in.
    static let rise: CGFloat = 24

    private weak var photoView: UIImageView?
    private let reducesMotion: Bool

    init(from photoView: UIImageView?, reducesMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
        self.photoView = photoView
        self.reducesMotion = reducesMotion
    }

    /// True when the photo moves; the fade needs no photo and no motion.
    var movesPhoto: Bool {
        !reducesMotion && photoView?.image != nil
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        movesPhoto ? Self.moveDuration : Self.fadeDuration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to), let toController = context.viewController(forKey: .to) else {
            context.completeTransition(false)
            return
        }
        toView.frame = context.finalFrame(for: toController)
        context.containerView.addSubview(toView)
        toView.layoutIfNeeded()

        let details = (toController as? UINavigationController)?.viewControllers.first as? FileDetailsViewController
        guard movesPhoto, let source = photoView, let image = source.image, let slot = details?.pictureImageView() else {
            fade(toView, in: context)
            return
        }
        // Only the list rises; the bar cross-fades in place, so its X and title do not double up.
        move(image, from: source, to: slot, rising: details?.collectionView ?? toView, in: context)
    }

    private func fade(_ toView: UIView, in context: UIViewControllerContextTransitioning) {
        toView.alpha = 0
        UIView.animate(withDuration: Self.fadeDuration, animations: { toView.alpha = 1 }) { _ in
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    private func move(_ image: UIImage, from source: UIImageView, to slot: UIImageView, rising: UIView, in context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        guard let toView = context.view(forKey: .to) else {
            context.completeTransition(false)
            return
        }
        let start = Self.fittedRect(for: image.size, in: source.convert(source.bounds, to: container))
        let end = Self.fittedRect(for: image.size, in: slot.convert(slot.bounds, to: container))

        let photo = UIImageView(image: image)
        photo.contentMode = .scaleAspectFit
        photo.frame = start
        container.addSubview(photo)
        source.alpha = 0
        slot.alpha = 0
        toView.alpha = 0
        rising.transform = CGAffineTransform(translationX: 0, y: Self.rise)

        let animator = UIViewPropertyAnimator(duration: Self.moveDuration, curve: .easeInOut) {
            photo.frame = end
            toView.alpha = 1
            rising.transform = .identity
        }
        animator.addCompletion { _ in
            if slot.image == nil {
                slot.image = image
            }
            slot.alpha = 1
            source.alpha = 1
            photo.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
        animator.startAnimation()
    }

    /// Where an aspect-fit image draws inside a frame: scaled to fit and centred.
    static func fittedRect(for imageSize: CGSize, in frame: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, frame.width > 0, frame.height > 0 else { return frame }
        let scale = min(frame.width / imageSize.width, frame.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
    }
}
