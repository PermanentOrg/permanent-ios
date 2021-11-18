//
//  ProfilePageFooterCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class ProfilePageFooterCollectionViewCell: UICollectionReusableView {

    static let identifier = "ProfilePageFooterCollectionViewCell"
    
    @IBOutlet weak var lineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lineView.backgroundColor = .darkGray
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

}
