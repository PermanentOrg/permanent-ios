//
//  ArchiveScreenPendingArchiveDetailsTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.09.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class ArchiveScreenPendingArchiveDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var archiveThumbnailImage: UIImageView!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var archiveAccessLabel: UILabel!
    @IBOutlet var approveButton: RoundedButton!
    @IBOutlet var denyButton: RoundedButton!
    
    var approveAction: ButtonAction?
    var denyAction: ButtonAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .gray
        
        archiveNameLabel.font = Text.style16.font
        archiveNameLabel.textColor = .darkBlue
        
        archiveAccessLabel.font = Text.style8.font
        archiveAccessLabel.textColor = .darkBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        contentView.backgroundColor = .white
    }
    
    func updateCell(withArchiveVO archiveVO: ArchiveVOData, isDefault: Bool) {
        guard let thumbURL = archiveVO.thumbURL500,
              let archiveName = archiveVO.fullName,
              let accessLevel = archiveVO.accessRole else { return }
        archiveThumbnailImage.image = nil
        archiveThumbnailImage.load(urlString: thumbURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        archiveAccessLabel.text = "Access: <ACCESS_LEVEL>".localized().replacingOccurrences(of: "<ACCESS_LEVEL>", with: AccessRole.roleForValue(accessLevel).groupName)
        
        approveButton.configureActionButtonUI(title: .accept, bgColor: .darkBlue)
        denyButton.configureActionButtonUI(title: .decline, bgColor: .brightRed)
    }
    
    @IBAction func approveAction(_ sender: UIButton) {
        approveAction?()
    }
    
    @IBAction func denyAction(_ sender: UIButton) {
        denyAction?()
    }
    
}
