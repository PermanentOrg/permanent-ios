//
//  FileDetailsTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class FileDetailsTopCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    static let identifier = "FileDetailsTopCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with urlString: String) {
        
        imageView.image = .placeholder
        imageView.load(urlString: urlString)

    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
