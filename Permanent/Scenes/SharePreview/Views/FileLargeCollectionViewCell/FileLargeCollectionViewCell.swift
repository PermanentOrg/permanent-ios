//  
//  FileLargeCollectionViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11.01.2021.
//

import UIKit
import SDWebImage

class FileLargeCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties
    
    @IBOutlet var fileThumbImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    var file: File? {
        didSet {
            nameLabel.text = file?.name
            let url = URL(string: file?.thumbStringURL)
            fileThumbImage.sd_setImage(with: url)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        fileThumbImage.contentMode = .scaleAspectFill        
        nameLabel.textColor = .textPrimary
        nameLabel.font = Text.style20.font
    }
}