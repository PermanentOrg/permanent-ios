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
    
    var acceptButtonAction: ((ArchiveScreenPendingArchiveDetailsTableViewCell) -> Void)?
    var declineButtonAction: ((ArchiveScreenPendingArchiveDetailsTableViewCell) -> Void)?
    
    var archiveData: ArchiveVOData?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .gray
        
        archiveNameLabel.font = Text.style16.font
        archiveNameLabel.textColor = .darkBlue
        
        archiveAccessLabel.font = Text.style8.font
        archiveAccessLabel.textColor = .darkBlue
    }
    
    func updateCell(withArchiveVO archiveVO: ArchiveVOData) {
        guard let thumbURL = archiveVO.thumbURL500,
              let archiveName = archiveVO.fullName,
              let accessLevel = archiveVO.accessRole else { return }
        archiveThumbnailImage.image = nil
        archiveThumbnailImage.load(urlString: thumbURL)
        
        archiveNameLabel.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        archiveAccessLabel.text = "Access: <ACCESS_LEVEL>".localized().replacingOccurrences(of: "<ACCESS_LEVEL>", with: AccessRole.roleForValue(accessLevel).groupName)
        
        approveButton.configureActionButtonUI(title: .accept, bgColor: .darkBlue)
        denyButton.configureActionButtonUI(title: .decline, bgColor: .brightRed)
        
        archiveData = archiveVO
    }
    
    @IBAction func acceptAction(_ sender: UIButton) {
        acceptButtonAction?(self)
    }
    
    @IBAction func declineAction(_ sender: UIButton) {
        declineButtonAction?(self)
    }
    
}
