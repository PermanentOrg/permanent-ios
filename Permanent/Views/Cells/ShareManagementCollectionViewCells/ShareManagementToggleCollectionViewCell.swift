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
    
    var viewModel: ShareLinkViewModel?
    var cellType: ShareManagementCellType?
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .backgroundPrimary
        
        cellTitleLabel.font = TextFontStyle.style34.font
        cellTitleLabel.textColor = .darkBlue
        
        cellSubtitleLabel.font = TextFontStyle.style38.font
        cellSubtitleLabel.textColor = .middleGray
    }
    
    func configure(cellType: ShareManagementCellType, viewModel: ShareLinkViewModel) {
        self.viewModel = viewModel
        self.cellType = cellType
        if cellType == .autoApprove {
            activateSwitch.setOn(viewModel.shareVO?.autoApproveToggle == 1, animated: false)
            cellTitleLabel.text = "Auto approve".localized()
            cellSubtitleLabel.text = "Automatically approve requests for share access.".localized()
        } else {
            activateSwitch.setOn(viewModel.shareVO?.previewToggle == 1, animated: false)
            cellTitleLabel.text = "Share preview".localized()
            cellSubtitleLabel.text = "Show a thumbnail of this shared item to link recipients.".localized()
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func switchTapAction(_ sender: Any) {
        if cellType == .autoApprove {
            viewModel?.updateLinkWithChangedField(autoApproveToggle: activateSwitch.isOn ? 1 : 0, then: { _, error in
                if error != nil { self.activateSwitch.isOn = !self.activateSwitch.isOn }
            })
        } else {
            viewModel?.updateLinkWithChangedField(previewToggle: activateSwitch.isOn ? 1 : 0, then: { _, error in
                if error != nil { self.activateSwitch.isOn = !self.activateSwitch.isOn }
            })
        }
    }
}
