//
//  ArchiveScreenTopSectionTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.09.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class ArchiveScreenSectionTitleTableViewCell: UITableViewCell {

    @IBOutlet weak var topSectionTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configureUI() {
        topSectionTitleLabel.font = Text.style3.font
        topSectionTitleLabel.textColor = .darkBlue
    }
    
    func updateCell(with type: Int = 1) {
        switch type {
        case 1:
            topSectionTitleLabel.text = "Pending Archives:".localized()
        default:
            topSectionTitleLabel.text = "Choose Archives:".localized()
        }
    }
    
}
