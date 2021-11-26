//
//  ProfilePageAboutCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageAboutCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageAboutCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentLabel.text = ""
        contentLabel.textColor = .darkGray
        contentLabel.font = Text.style12.font
    }
    
    func configure(_ shortDescription: String?, _ longDescription: String?) {
        var contentText = ""
        if let shortDescription = shortDescription {
            contentText.append(contentsOf: "\(shortDescription) \n\n")
        }
        
        if let longDescription = longDescription {
            contentText.append(contentsOf: longDescription)
        }
        
        contentLabel.text = contentText
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
