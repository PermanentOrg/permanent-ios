//
//  LeftSideHeaderTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.08.2021.
//

import UIKit

class LeftSideHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var archiveImage: UIImageView!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var actionDescriptionLabel: UILabel!
    
    var isEnabled = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        archiveNameLabel.font = Text.style7.font
        archiveNameLabel.textColor = .white
        
        actionDescriptionLabel.font = Text.style16.font
        actionDescriptionLabel.textColor = .white
        actionDescriptionLabel.text = "Tap to manage archives".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        contentView.backgroundColor = selected ? .mainPurple : .primary
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        contentView.backgroundColor = highlighted ? .mainPurple : .primary
    }
    
    func updateCell(with thumbnailURL: String, archiveName: String) {
        archiveImage.image = nil
        archiveImage.load(urlString: thumbnailURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
    }
}