//
//  ShareMangementAdditionalOptionCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareMangementAdditionalOptionCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareMangementAdditionalOptionCollectionViewCell"

    @IBOutlet weak var optionThumbnailImage: UIImageView!
    @IBOutlet weak var optionTitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        optionTitleLabel.font = Text.style34.font
    }
    
    func configure(cellType: ShareManagementCellType) {
        switch cellType {
        case .revokeLinkOption:
            optionThumbnailImage.image = UIImage(named: "leaveShare")?.withRenderingMode(.alwaysTemplate)
            optionThumbnailImage.tintColor = .temporaryRed
            optionTitleLabel.text = "Revoke link".localized()
            optionTitleLabel.textColor = .temporaryRed
        case .shareLinkOption:
            optionThumbnailImage.image = UIImage(named: "Share Other")?.withRenderingMode(.alwaysTemplate)
            optionThumbnailImage.tintColor = .darkBlue
            optionTitleLabel.text = "Share link".localized()
            optionTitleLabel.textColor = .black
        default:
            optionThumbnailImage.image = UIImage(named: "")
            optionTitleLabel.text = nil
        }
    }
    
    override func prepareForReuse() {
        optionThumbnailImage.image = UIImage(named: "")
        optionTitleLabel.text = nil
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
