//
//  ProfilePageArchiveCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageArchiveCollectionViewCell: ProfilePageBaseCollectionViewCell {
    
    static let identifier = "ProfilePageArchiveCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
