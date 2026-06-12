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

/// Full-screen overlay rendering the image preview loading / failure states (VSP-1768, Figma node 24502-17330).
/// The blur is a gaussian-blurred copy of the thumbnail, aspect-fitted like the photo beneath,
/// so letterbox areas around the image stay black (per design); it never touches the image itself.
class ImagePreviewStateOverlayView: UIView {
    var onRetryTapped: (() -> Void)?

    private let blurredImageView = UIImageView()
    private let noThumbnailBackground = UIView()
    private let logoImageView = UIImageView()
    private let messageCard = UIView()
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    // Gradient loader composited with the `screen` blend mode per the Figma component
    // (Circles/Spinner-Two-Circles uses mix-blend-screen), which lightens it against
    // the blurred photo beneath — reads as the "semi-transparent white" loader from S2.
    private let spinnerHost = UIHostingController(rootView: GradientSemiCirclesLoaderView(frameWidth: 48, frameHeight: 48))

    private var sourceImage: UIImage?
    private var spinnerDelayWorkItem: DispatchWorkItem?

    /// The loader appears only when the full image hasn't arrived within this interval (S2).
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

        noThumbnailBackground.backgroundColor = UIColor(white: 0.88, alpha: 1)
        noThumbnailBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noThumbnailBackground)

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        noThumbnailBackground.addSubview(logoImageView)
        Self.blurred(UIImage(named: "logo_preview")) { [weak self] blurredLogo in
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
            messageCard.isHidden = true
            // S2: the loader appears only when the full image hasn't arrived within 500 ms,
            // so fast loads never flash a spinner.
            spinnerHost.view.isHidden = true
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.spinnerHost.view.alpha = 0
                self.spinnerHost.view.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    self.spinnerHost.view.alpha = 1
                }
            }
            spinnerDelayWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.spinnerAppearanceDelay, execute: workItem)

        case .failed(let hasThumbnail):
            showOverlay()
            blurredImageView.isHidden = !hasThumbnail
            noThumbnailBackground.isHidden = hasThumbnail
            spinnerHost.view.isHidden = true
            showCard(icon: "arrow.clockwise", message: "\(String.couldntLoadImage)\n\(String.tapToRetry)")

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
        spinnerHost.view.alpha = 1
    }

    /// Gaussian-blurs an image off the main thread, clamping the edges so the blur
    /// doesn't fade to transparent at the borders.
    private static func blurred(_ image: UIImage?, radius: Double = 24, completion: @escaping (UIImage?) -> Void) {
        guard let image = image, let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = ciImage.clampedToExtent()
            filter.radius = Float(radius)

            let context = CIContext()
            guard let output = filter.outputImage,
                  let cgImage = context.createCGImage(output, from: ciImage.extent) else {
                DispatchQueue.main.async { completion(image) }
                return
            }
            let result = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func showCard(icon: String, message: String) {
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
