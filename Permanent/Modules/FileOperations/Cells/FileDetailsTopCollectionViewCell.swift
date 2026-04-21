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
        guard let thumbnailURL = URL(string: thumbnailURLString) else { return }
        
        // Determine the full-res download URL if available
        let fullResURLString = viewModel.fileVO()?.downloadURL
        let fullResURL = fullResURLString.flatMap { URL(string: $0) }
        
        imageView.sd_setImage(with: thumbnailURL) { [weak self] _, error, _, _ in
            guard let self = self else { return }
            
            if let fullResURL = fullResURL, fullResURL != thumbnailURL {
                // Stage 2: Upgrade to full-res from download URL
                self.imageView.sd_setImage(
                    with: fullResURL,
                    placeholderImage: self.imageView.image,
                    options: [.avoidAutoSetImage, .retryFailed],
                    progress: nil
                ) { [weak self] image, _, cacheType, _ in
                    guard let self = self, let image = image else { return }
                    self.activityIndicator.stopAnimating()
                    
                    if cacheType == .memory {
                        self.imageView.image = image
                    } else {
                        UIView.transition(with: self.imageView, duration: 0.3, options: .transitionCrossDissolve) {
                            self.imageView.image = image
                        }
                    }
                }
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
