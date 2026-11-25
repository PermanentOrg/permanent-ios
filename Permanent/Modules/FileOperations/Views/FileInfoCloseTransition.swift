//
//  FileInfoCloseTransition.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import UIKit

/// Closes the Info screen to the preview, or opens the preview over an Info screen a list opened: the photo glides from
/// the picture slot to where the preview draws it while the Info screen fades and its list sinks. Reduce Motion, or no photo: a fade.
final class FileInfoCloseTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var photoView: UIImageView?
    private let reducesMotion: Bool

    /// `photoView` is the preview's image view the photo lands on.
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
        // The screen that fades, and the alpha it fades to: the closing Info screen out, or the opening preview in.
        var fading = (view: fromView, to: CGFloat(0))
        if let toView = context.view(forKey: .to), let toController = context.viewController(forKey: .to) {
            toView.frame = context.finalFrame(for: toController)
            if toController.presentingViewController === fromController {
                // The Info screen presents the preview: it comes in above and fades in over the sinking list.
                toView.alpha = 0
                container.addSubview(toView)
                fading = (view: toView, to: 1)
            } else {
                // A full-screen presentation took the preview out of the window; it comes back under the Info screen.
                container.insertSubview(toView, belowSubview: fromView)
            }
            toView.layoutIfNeeded()
        }

        let details = (fromController as? UINavigationController)?.viewControllers.first as? FileDetailsViewController
        guard movesPhoto, let target = photoView, let slot = details?.pictureImageView(), let image = target.image ?? slot.image else {
            fade(fading, in: context)
            return
        }
        move((image: image, slot: slot, target: target), sinking: details?.collectionView ?? fromView, fading: fading, in: context)
    }

    private func fade(_ fading: (view: UIView, to: CGFloat), in context: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: FileInfoOpenTransition.fadeDuration, animations: { fading.view.alpha = fading.to }) { _ in
            fading.view.alpha = 1
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    /// `glide` is the photo and the two image views it travels between: the Info slot and the preview's.
    private func move(_ glide: (image: UIImage, slot: UIImageView, target: UIImageView), sinking: UIView, fading: (view: UIView, to: CGFloat), in context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        let start = FileInfoOpenTransition.fittedRect(for: glide.image.size, in: glide.slot.convert(glide.slot.bounds, to: container))
        let end = FileInfoOpenTransition.fittedRect(for: glide.image.size, in: glide.target.convert(glide.target.bounds, to: container))

        let photo = UIImageView(image: glide.image)
        photo.contentMode = .scaleAspectFit
        photo.frame = start
        container.addSubview(photo)
        glide.slot.alpha = 0
        glide.target.alpha = 0

        let animator = UIViewPropertyAnimator(duration: FileInfoOpenTransition.moveDuration, curve: .easeInOut) {
            photo.frame = end
            fading.view.alpha = fading.to
            sinking.transform = CGAffineTransform(translationX: 0, y: FileInfoOpenTransition.rise)
        }
        animator.addCompletion { _ in
            glide.target.alpha = 1
            glide.slot.alpha = 1
            fading.view.alpha = 1
            sinking.transform = .identity
            photo.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
        animator.startAnimation()
    }
}
