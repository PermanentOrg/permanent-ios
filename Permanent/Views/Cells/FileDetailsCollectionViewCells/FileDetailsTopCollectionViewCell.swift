//
//  FileDetailsTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsTopCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imageLoadedCallback: ((FileDetailsTopCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsTopCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with urlString: String) {
        activityIndicator.startAnimating()
        
        imageView.image = nil
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
