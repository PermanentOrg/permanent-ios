//
//  ProfilePageHeaderCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class ProfilePageHeaderCollectionViewCell: UICollectionReusableView {

    static let identifier = "ProfilePageHeaderCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

}
