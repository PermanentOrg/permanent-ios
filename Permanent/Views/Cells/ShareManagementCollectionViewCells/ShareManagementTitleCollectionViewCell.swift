//
//  SectionTitleCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2022.
//

import UIKit

class ShareManagementTitleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "ShareManagementTitleCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure() {
        imageView.image = UIImage(named: "manageSharing")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .lightGray
        
        titleLabel.text = "Share Management".localized()
        titleLabel.font = TextFontStyle.style35.font
        titleLabel.textColor = .primary
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
