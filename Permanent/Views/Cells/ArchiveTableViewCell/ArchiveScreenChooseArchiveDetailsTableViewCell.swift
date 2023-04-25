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
    @IBOutlet weak var currentArchiveDefaultIcon: UIImageView!
    
    var rightButtonAction: ((ArchiveScreenChooseArchiveDetailsTableViewCell) -> Void)?
    
    var archiveData: ArchiveVOData?
    
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
    
    func updateCell(withArchiveVO archiveVO: ArchiveVOData, isDefault: Bool, isManaging: Bool) {
        guard let thumbURL = URL(string: archiveVO.thumbURL500),
            let archiveName = archiveVO.fullName,
            let accessLevel = archiveVO.accessRole else { return }
        archiveThumbnailImage.image = nil
        archiveThumbnailImage.sd_setImage(with: thumbURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        archiveAccessLabel.text = "Access: <ACCESS_LEVEL>".localized().replacingOccurrences(of: "<ACCESS_LEVEL>", with: AccessRole.roleForValue(accessLevel).groupName)
        
        rightButton.isHidden = false
        if isDefault {
            if AppEnvironment.shared.isRunningInAppExtension() {
                rightButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
                
                rightButton.isEnabled = false
            } else {
                currentArchiveDefaultIcon.isHidden = false
                
                rightButton.setImage(UIImage(named: "more"), for: .normal)
                rightButton.isEnabled = true
            }
            
        } else if isManaging {
            if !AppEnvironment.shared.isRunningInAppExtension() {
                rightButton.setImage(UIImage(named: "more"), for: .normal)
                rightButton.isEnabled = true
                currentArchiveDefaultIcon.isHidden = true
            }
        } else {
            rightButton.isHidden = true
        }
        
        archiveData = archiveVO
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
}
