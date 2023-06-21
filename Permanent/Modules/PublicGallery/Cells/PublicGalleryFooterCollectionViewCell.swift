//
//  PublicGalleryFooterCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.03.2022.
//

import UIKit

class PublicGalleryFooterCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "PublicGalleryFooterCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure() {
        
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
