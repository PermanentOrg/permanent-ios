//
//  ArchiveScreenTopSectionTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.09.2021.
//

import UIKit

class ArchiveScreenSectionTitleTableViewCell: UITableViewHeaderFooterView {

    @IBOutlet weak var topSectionTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    func configureUI() {
        contentView.isUserInteractionEnabled = false
        topSectionTitleLabel.backgroundColor = .white
        topSectionTitleLabel.font = Text.style3.font
        topSectionTitleLabel.textColor = .darkBlue
    }
    
    func updateCell(with type: ArchiveVOData.Status = .ok) {
        switch type {
        case .pending:
            topSectionTitleLabel.text = "Pending Archives:".localized()
        case .ok:
            topSectionTitleLabel.text = "Choose Archive:".localized()
        default:
            topSectionTitleLabel.text = ""
        }
    }
    
}
