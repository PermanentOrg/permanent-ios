//
//  FileDetailsTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit
import SDWebImage

class FileDetailsTopCollectionViewCell: FileDetailsBaseCollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static let identifier = "FileDetailsTopCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        super.configure(withViewModel: viewModel, type: type)
        
        activityIndicator.startAnimating()

        imageView.image = nil

        // Stage 1: Load the 256px thumbnail quickly
        let thumbnailURLString = viewModel.file.preferredThumbnailURL ?? viewModel.fileThumbnailURL() ?? ""
        guard let thumbnailURL = URL(string: thumbnailURLString) else {
            // No thumbnail to load — don't leave the spinner running forever.
            activityIndicator.stopAnimating()
            return
        }

        // Only images upgrade to full resolution. For documents/audio/video the download
        // URL is the raw file (a PDF binary, etc.), which SDWebImage can't decode as an
        // image — attempting it always fails and previously left the spinner spinning.
        // The 256px thumbnail is the preview for those types. Use the record's content
        // type (reliable) rather than the listing file.type.
        let fullResURL: URL? = {
            guard let fileVO = viewModel.fileVO() else { return nil }
            // Upgrade only for images: an image content type, or (as a fallback for
            // records with a missing content type) an image file type. Documents/audio/
            // video are excluded so we don't try to decode a raw binary as an image.
            let isImage = fileVO.contentType?.hasPrefix("image/") == true || viewModel.file.type == .image
            guard isImage, let urlString = fileVO.downloadURL else { return nil }
            return URL(string: urlString)
        }()

        imageView.sd_setImage(with: thumbnailURL) { [weak self] _, _, _, _ in
            guard let self = self else { return }

            guard let fullResURL = fullResURL, fullResURL != thumbnailURL else {
                self.activityIndicator.stopAnimating()
                return
            }

            // Stage 2: Upgrade to full-res from download URL (images only)
            self.imageView.sd_setImage(
                with: fullResURL,
                placeholderImage: self.imageView.image,
                options: [.avoidAutoSetImage, .retryFailed],
                progress: nil
            ) { [weak self] image, _, cacheType, _ in
                guard let self = self else { return }
                // Always stop the spinner, even if the full-res load failed — keep the
                // thumbnail rather than swallowing the failure with the spinner running.
                self.activityIndicator.stopAnimating()
                guard let image = image else { return }

                if cacheType == .memory {
                    self.imageView.image = image
                } else {
                    UIView.transition(with: self.imageView, duration: 0.3, options: .transitionCrossDissolve) {
                        self.imageView.image = image
                    }
                }
            }
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
