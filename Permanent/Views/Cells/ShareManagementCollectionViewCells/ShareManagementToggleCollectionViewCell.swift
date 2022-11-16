//
//  ShareManagementToggleCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementToggleCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementToggleCollectionViewCell"
    
    @IBOutlet weak var cellTitleLabel: UILabel!
    @IBOutlet weak var cellSubtitleLabel: UILabel!
    @IBOutlet weak var activateSwitch: UISwitch!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .backgroundPrimary
        
        cellTitleLabel.font = Text.style34.font
        cellTitleLabel.textColor = .darkBlue
        
        cellSubtitleLabel.font = Text.style38.font
        cellSubtitleLabel.textColor = .middleGray
    }
    
    func configure(cellType: ShareManagementCellType) {
        if cellType == .autoApprove {
            cellTitleLabel.text = "Auto approve".localized()
            cellSubtitleLabel.text = "Automatically approve requests for share access.".localized()
        } else {
            cellTitleLabel.text = "Share preview".localized()
            cellSubtitleLabel.text = "Show a thumbnail of this shared item to link recipients.".localized()
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func switchTapAction(_ sender: Any) {
    }
    
}
