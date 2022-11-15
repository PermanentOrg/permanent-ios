//
//  ShareMangementAdditionalOptionCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareMangementAdditionalOptionCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareMangementAdditionalOptionCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
