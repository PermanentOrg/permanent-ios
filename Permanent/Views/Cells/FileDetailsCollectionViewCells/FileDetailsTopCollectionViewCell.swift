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
    
    var imageLoadedCallback: ((FileDetailsTopCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsTopCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        super.configure(withViewModel: viewModel, type: type)
        
        activityIndicator.startAnimating()
        
        imageView.image = nil
        let urlString = viewModel.recordVO?.recordVO?.thumbURL2000 ?? ""
        imageView.load(urlString: urlString) { _ in
            if let imageLoadedCallback = self.imageLoadedCallback {
                imageLoadedCallback(self)
            }
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
