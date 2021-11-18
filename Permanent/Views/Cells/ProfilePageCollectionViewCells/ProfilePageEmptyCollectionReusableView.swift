//
//  ProfilePageEmptyCollectionReusableView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class ProfilePageEmptyCollectionReusableView: UICollectionReusableView {

    static let identifier = "ProfilePageEmptyCollectionReusableView"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
