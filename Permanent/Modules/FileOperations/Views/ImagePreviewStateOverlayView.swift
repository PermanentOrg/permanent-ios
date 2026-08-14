//
//  ImagePreviewStateOverlayView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.06.2026.
//

import UIKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Full-screen overlay for the image preview's loading and failure states. The blur is a copy of
/// the thumbnail, aspect-fitted like the photo beneath, so letterbox areas stay black.
class ImagePreviewStateOverlayView: UIView {
    var onRetryTapped: (() -> Void)?
    /// Selects the noun in the failed-load copy: "Couldn't load image" for photos,
    /// "Couldn't load file" for video/audio/documents.
    var isImageContent = true

    private let blurredImageView = UIImageView()
    private let noThumbnailBackground = UIView()
    private let logoImageView = UIImageView()
    private let messageCard = UIView()
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    // The loader composites with the `screen` blend mode, which lightens it against the blurred
    // photo beneath and reads as a semi-transparent white.
    private let spinnerHost = UIHostingController(rootView: GradientSemiCirclesLoaderView(frameWidth: 48, frameHeight: 48))

    private var sourceImage: UIImage?
    private var spinnerDelayWorkItem: DispatchWorkItem?
    /// Resting opacity of the loader. Over a photo the screen blend keeps it soft at full alpha; over
    /// the light neutral background the blend vanishes, so a lower alpha stands in.
    private var spinnerTargetAlpha: CGFloat = 1

    /// The loader appears only when the full image hasn't arrived within this interval, so a fast
    /// load never flashes a spinner.
    static let spinnerAppearanceDelay: TimeInterval = 0.5
    /// Blur + loader fade-out duration once the full image is rendered (S3/S4).
    static let fadeOutDuration: TimeInterval = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        isHidden = true
        accessibilityIdentifier = "imagePreviewStateOverlay"

        noThumbnailBackground.backgroundColor = UIColor(white: 0.88, alpha: 1)
        noThumbnailBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noThumbnailBackground)

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.alpha = 0.7
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        noThumbnailBackground.addSubview(logoImageView)
        // Soft edges: the logo glow must melt into the background, not end in a rectangle.
        Self.blurred(UIImage(named: "logo_preview"), softEdges: true) { [weak self] blurredLogo in
            self?.logoImageView.image = blurredLogo
        }

        blurredImageView.contentMode = .scaleAspectFit
        blurredImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurredImageView)

        spinnerHost.view.backgroundColor = .clear
        spinnerHost.view.layer.compositingFilter = "screenBlendMode"
        spinnerHost.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinnerHost.view)

        messageCard.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        messageCard.layer.cornerRadius = 24
        messageCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageCard)

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.accessibilityIdentifier = "imagePreviewStateMessage"

        let cardStack = UIStackView(arrangedSubviews: [iconImageView, messageLabel])
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = 24
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        messageCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            noThumbnailBackground.topAnchor.constraint(equalTo: topAnchor),
            noThumbnailBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            noThumbnailBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            noThumbnailBackground.trailingAnchor.constraint(equalTo: trailingAnchor),

            logoImageView.centerXAnchor.constraint(equalTo: noThumbnailBackground.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: noThumbnailBackground.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalTo: noThumbnailBackground.widthAnchor, multiplier: 0.66),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 0.75),

            blurredImageView.topAnchor.constraint(equalTo: topAnchor),
            blurredImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurredImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurredImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            spinnerHost.view.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerHost.view.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinnerHost.view.widthAnchor.constraint(equalToConstant: 48),
            spinnerHost.view.heightAnchor.constraint(equalToConstant: 48),

            messageCard.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageCard.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageCard.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -48),

            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            cardStack.topAnchor.constraint(equalTo: messageCard.topAnchor, constant: 32),
            cardStack.bottomAnchor.constraint(equalTo: messageCard.bottomAnchor, constant: -32),
            cardStack.leadingAnchor.constraint(equalTo: messageCard.leadingAnchor, constant: 32),
            cardStack.trailingAnchor.constraint(equalTo: messageCard.trailingAnchor, constant: -32)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        addGestureRecognizer(tapGesture)
    }

    @objc private func overlayTapped() {
        // Acknowledge the tap with a press animation, so there is feedback even when the retry can't
        // proceed or fails again immediately.
        if !messageCard.isHidden {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction], animations: {
                self.messageCard.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                self.messageCard.alpha = 0.6
            }, completion: { _ in
                UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction], animations: {
                    self.messageCard.transform = .identity
                    self.messageCard.alpha = 1
                })
            })
        }
        onRetryTapped?()
    }

    /// Sets the image the blur is generated from (the loaded thumbnail). The blurred copy
    /// is aspect-fitted like the photo, so the blur covers exactly the photo's on-screen rect.
    func setSourceImage(_ image: UIImage?) {
        guard image !== sourceImage else { return }
        sourceImage = image
        guard let image = image else {
            blurredImageView.image = nil
            return
        }
        Self.blurred(image) { [weak self] blurredImage in
            guard self?.sourceImage === image else { return }
            self?.blurredImageView.image = blurredImage
        }
    }

    func render(_ state: ImagePreviewState) {
        spinnerDelayWorkItem?.cancel()
        spinnerDelayWorkItem = nil

        switch state {
        case .idle, .loadingThumbnail:
            layer.removeAllAnimations()
            alpha = 1
            isHidden = true

        case .loaded:
            // S3/S4: full image is beneath — fade the blur and loader out together (ease-out).
            guard !isHidden else { break }
            UIView.animate(withDuration: Self.fadeOutDuration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                self.alpha = 0
            } completion: { _ in
                self.isHidden = true
                self.alpha = 1
            }

        case .loadingFullRes(let hasThumbnail):
            showOverlay()
            blurredImageView.isHidden = !hasThumbnail
            noThumbnailBackground.isHidden = hasThumbnail
            updateSpinnerBlend(overPhoto: hasThumbnail)
            messageCard.isHidden = true
            // The loader appears only when the full image hasn't arrived within 500 ms,
            // so fast loads never flash a spinner.
            spinnerHost.view.isHidden = true
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.spinnerHost.view.alpha = 0
                self.spinnerHost.view.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    self.spinnerHost.view.alpha = self.spinnerTargetAlpha
                }
            }
            spinnerDelayWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.spinnerAppearanceDelay, execute: workItem)

        case .failed(let hasThumbnail):
            showOverlay()
            blurredImageView.isHidden = !hasThumbnail
            noThumbnailBackground.isHidden = hasThumbnail
            spinnerHost.view.isHidden = true
            let failedTitle = isImageContent ? String.couldntLoadImage : String.couldntLoadFile
            showCard(icon: "arrow.clockwise", message: "\(failedTitle)\n\(String.tapToRetry)")

        case .offline(let hasThumbnail):
            showOverlay()
            blurredImageView.isHidden = !hasThumbnail
            noThumbnailBackground.isHidden = hasThumbnail
            spinnerHost.view.isHidden = true
            showCard(icon: "wifi.slash", message: "\(String.youreOffline)\n\(String.connectToLoadFullQuality)")
        }
    }

    private func showOverlay() {
        layer.removeAllAnimations()
        alpha = 1
        isHidden = false
        spinnerHost.view.alpha = spinnerTargetAlpha
    }

    /// Over photo blur, screen blending at full alpha keeps the loader soft. Over the light neutral
    /// background the blend vanishes, so a lower alpha melts it into the logo glow instead.
    private func updateSpinnerBlend(overPhoto: Bool) {
        spinnerHost.view.layer.compositingFilter = overPhoto ? "screenBlendMode" : nil
        spinnerTargetAlpha = overPhoto ? 1 : 0.5
        spinnerHost.view.alpha = spinnerTargetAlpha
    }

    // CIContext creation is expensive (~100-300 ms); share one across blurs so the
    // placeholder appears within a frame or two of the thumbnail.
    private static let blurContext = CIContext()

    /// Blurs an image off the main thread. `softEdges` false clamps the edges for a full-bleed photo
    /// placeholder; true fades into transparency past the bounds, for the logo glow.
    private static func blurred(_ image: UIImage?, radius: Double = 24, softEdges: Bool = false, completion: @escaping (UIImage?) -> Void) {
        guard let image = image, let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = softEdges ? ciImage : ciImage.clampedToExtent()
            filter.radius = Float(radius)

            let renderRect = softEdges ? ciImage.extent.insetBy(dx: -2 * radius, dy: -2 * radius) : ciImage.extent
            guard let output = filter.outputImage,
                  let cgImage = blurContext.createCGImage(output, from: renderRect) else {
                DispatchQueue.main.async { completion(image) }
                return
            }
            let result = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func showCard(icon: String, message: String) {
        // Reset any leftover press-animation transform/alpha before showing.
        messageCard.transform = .identity
        messageCard.alpha = 1
        iconImageView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24
        paragraphStyle.maximumLineHeight = 24
        paragraphStyle.alignment = .center
        messageLabel.attributedText = NSAttributedString(
            string: message,
            attributes: [
                .font: UIFont(name: "Usual-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
        messageCard.isHidden = false
    }
}
