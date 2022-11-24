//
//  ShareManagementHeaderCollectionReusableView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 23.11.2022.
//

import UIKit

class ShareManagementHeaderCollectionReusableView: UICollectionReusableView {
    static let identifier = "ShareManagementHeaderCollectionReusableView"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = .middleGray
        titleLabel.font = Text.style37.font
        
        badgeLabel.backgroundColor = .paleRed
        badgeLabel.textColor = .white
        badgeLabel.font = Text.style40.font
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.clipsToBounds = true
    }
    
    func configure(withTitle title: String, badgeValue badge: Int?) {
        titleLabel.text = title
        
        if let badge = badge {
            badgeLabel.text = "\(badge)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.text = nil
            badgeLabel.isHidden = true
        }
    }
}
