//
//  ArchiveScreenDetailsTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.08.2021.
//

import UIKit

class ArchiveScreenChooseArchiveDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var archiveThumbnailImage: UIImageView!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var archiveAccessLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    
    var rightButtonAction: ((ArchiveScreenChooseArchiveDetailsTableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .gray
        
        archiveNameLabel.font = Text.style16.font
        archiveNameLabel.textColor = .darkBlue
        
        archiveAccessLabel.font = Text.style8.font
        archiveAccessLabel.textColor = .darkBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        contentView.backgroundColor = selected ? .barneyPurple : .white
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        contentView.backgroundColor = highlighted ? .barneyPurple : .white
    }
    
    func updateCell(withArchiveVO archiveVO: ArchiveVOData, isDefault: Bool) {
        guard let thumbURL = archiveVO.thumbURL500,
              let archiveName = archiveVO.fullName,
              let accessLevel = archiveVO.accessRole else { return }
        archiveThumbnailImage.image = nil
        archiveThumbnailImage.load(urlString: thumbURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        archiveAccessLabel.text = "Access: <ACCESS_LEVEL>".localized().replacingOccurrences(of: "<ACCESS_LEVEL>", with: AccessRole.roleForValue(accessLevel).groupName)
        
        if isDefault {
            if #available(iOS 13.0, *) {
                rightButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            } else {
                rightButton.setImage(UIImage(named: "star.fill"), for: .normal)
            }
            
            rightButton.isEnabled = false
        } else {
            rightButton.setImage(UIImage(named: "more"), for: .normal)
            rightButton.isEnabled = true
        }
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
}
