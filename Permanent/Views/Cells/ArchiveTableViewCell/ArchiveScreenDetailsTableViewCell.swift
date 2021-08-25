//
//  ArchiveScreenDetailsTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.08.2021.
//

import UIKit

class ArchiveScreenDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var archiveThumbnailImage: UIImageView!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var archiveAccessLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .gray
        
        archiveNameLabel.font = Text.style16.font
        archiveNameLabel.textColor = .darkBlue
        
        archiveAccessLabel.font = Text.style8.font
        archiveAccessLabel.textColor = .darkBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
    }
    
    func updateCell(with thumbnailURL: String = "", archiveName: String = "", accessLevel: String = "") {
        archiveThumbnailImage.image = nil
        archiveThumbnailImage.load(urlString: thumbnailURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        archiveAccessLabel.text = "Access: <ACCESS_LEVEL>".localized().replacingOccurrences(of: "<ACCESS_LEVEL>", with: accessLevel)
    }
}
