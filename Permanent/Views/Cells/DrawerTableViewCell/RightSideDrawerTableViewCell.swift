//
//  LeftSideDrawerTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.08.2021.
//

import UIKit

class RightSideDrawerTableViewCell: UITableViewCell {
    @IBOutlet weak var menuItemTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    
        menuItemTitleLabel.textColor = .darkBlue
        menuItemTitleLabel.font = Text.style10.font
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        contentView.backgroundColor = selected ? .mainPurple : .white
        menuItemTitleLabel.textColor = selected ? .white : .darkBlue
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        contentView.backgroundColor = highlighted ? .mainPurple : .white
        menuItemTitleLabel.textColor = highlighted ? .white : .darkBlue
    }

    func updateCell(with data: DrawerOption) {
        menuItemTitleLabel.text = data.title
    }
}
