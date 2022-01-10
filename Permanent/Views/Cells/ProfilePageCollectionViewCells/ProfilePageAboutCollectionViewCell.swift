//
//  ProfilePageAboutCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageAboutCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageAboutCollectionViewCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentLabel.text = ""
        contentLabel.textColor = .middleGray
        contentLabel.font = Text.style8.font
    }
    
    func configure(_ shortDescription: String?, _ longDescription: String?, _ archiveType: ArchiveType?) {
        var contentText = ""
        if let shortDescription = shortDescription {
            contentText.append(contentsOf: "\(shortDescription) \n\n")
        } else if let archiveType = archiveType {
            contentText.append(contentsOf: "\(archiveType.shortDescriptionHint) \n\n")
        }
        
        if let longDescription = longDescription {
            contentText.append(contentsOf: longDescription)
        } else if let archiveType = archiveType {
            contentText.append(contentsOf: "\(archiveType.longDescriptionHint) \n\n")
        }
        
        contentLabel.text = contentText
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
