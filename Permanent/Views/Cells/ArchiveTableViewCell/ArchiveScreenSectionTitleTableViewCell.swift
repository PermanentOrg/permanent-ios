//
//  ArchiveScreenTopSectionTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.09.2021.
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
