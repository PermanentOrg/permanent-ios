//
//  PublicGalleryHeaderCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.03.2022.
//

import UIKit

class PublicGalleryHeaderCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "PublicGalleryHeaderCollectionViewCell"
    
    @IBOutlet weak var sectionNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(section: PublicGalleryCellType) {
        switch section {
        case .onlineArchives:
            sectionNameLabel.font = Text.style32.font
            sectionNameLabel.textColor = .primary
            sectionNameLabel.text = "Your Public Archives".localized()
            
        case .popularPublicArchives:
            sectionNameLabel.font = Text.style32.font
            sectionNameLabel.textColor = .primary
            sectionNameLabel.text = "Public Popular Archives".localized()
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
