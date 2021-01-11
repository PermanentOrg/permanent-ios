//  
//  FileLargeCollectionViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11.01.2021.
//

import UIKit

class FileLargeCollectionViewCell: UICollectionViewCell {

    @IBOutlet var fileThumbImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        fileThumbImage.backgroundColor = .red
        fileThumbImage.contentMode = .scaleAspectFit
        
        nameLabel.textColor = .textPrimary
        nameLabel.font = Text.style20.font
        nameLabel.text = "Around the world"
    }
}
