//
//  FileDetailsTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsTopCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    var imageLoadedCallback: ((FileDetailsTopCollectionViewCell) -> Void)?
    
    static let identifier = "FileDetailsTopCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with urlString: String) {
        imageView.image = .placeholder
        imageView.load(urlString: urlString) { _ in
            if let imageLoadedCallback = self.imageLoadedCallback {
                imageLoadedCallback(self)
            }
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
