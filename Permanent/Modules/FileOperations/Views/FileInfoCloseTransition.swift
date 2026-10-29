//
//  FileInfoCloseTransition.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import UIKit

/// Closes the Info screen back to the preview: the photo glides from the picture slot to where the preview
/// draws it while the screen fades out and the list sinks. With Reduce Motion on, or no photo, it only fades.
final class FileInfoCloseTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var photoView: UIImageView?
    private let reducesMotion: Bool

    /// `photoView` is the preview's image view the photo returns to.
    init(to photoView: UIImageView?, reducesMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
        self.photoView = photoView
        self.reducesMotion = reducesMotion
    }

    var movesPhoto: Bool {
        !reducesMotion && photoView != nil
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        movesPhoto ? FileInfoOpenTransition.moveDuration : FileInfoOpenTransition.fadeDuration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.view(forKey: .from), let fromController = context.viewController(forKey: .from) else {
            context.completeTransition(false)
            return
        }
        let container = context.containerView
        // A full-screen presentation took the preview out of the window; it comes back under the Info screen.
        if let toView = context.view(forKey: .to), let toController = context.viewController(forKey: .to) {
            toView.frame = context.finalFrame(for: toController)
            container.insertSubview(toView, belowSubview: fromView)
            toView.layoutIfNeeded()
        }

        let details = (fromController as? UINavigationController)?.viewControllers.first as? FileDetailsViewController
        guard movesPhoto, let target = photoView, let slot = details?.pictureImageView(), let image = target.image ?? slot.image else {
            fade(fromView, in: context)
            return
        }
        move(image, from: slot, to: target, sinking: details?.collectionView ?? fromView, in: context)
    }

    private func fade(_ fromView: UIView, in context: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: FileInfoOpenTransition.fadeDuration, animations: { fromView.alpha = 0 }) { _ in
            fromView.alpha = 1
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    private func move(_ image: UIImage, from slot: UIImageView, to target: UIImageView, sinking: UIView, in context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        guard let fromView = context.view(forKey: .from) else {
            context.completeTransition(false)
            return
        }
        let start = FileInfoOpenTransition.fittedRect(for: image.size, in: slot.convert(slot.bounds, to: container))
        let end = FileInfoOpenTransition.fittedRect(for: image.size, in: target.convert(target.bounds, to: container))

        let photo = UIImageView(image: image)
        photo.contentMode = .scaleAspectFit
        photo.frame = start
        container.addSubview(photo)
        slot.alpha = 0
        target.alpha = 0

        let animator = UIViewPropertyAnimator(duration: FileInfoOpenTransition.moveDuration, curve: .easeInOut) {
            photo.frame = end
            fromView.alpha = 0
            sinking.transform = CGAffineTransform(translationX: 0, y: FileInfoOpenTransition.rise)
        }
        animator.addCompletion { _ in
            target.alpha = 1
            slot.alpha = 1
            fromView.alpha = 1
            sinking.transform = .identity
            photo.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
        animator.startAnimation()
    }
}
