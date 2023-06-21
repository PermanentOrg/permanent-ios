//
//  FileDetailsTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

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
        let urlString = viewModel.file.thumbnailURL2000 ?? viewModel.fileThumbnailURL() ?? ""
        guard let url = URL(string: urlString) else { return }
        
        imageView.sd_setImage(with: url) { image, error, cacheType, url in
            self.activityIndicator.stopAnimating()
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
