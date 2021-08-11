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
    
        menuItemTitleLabel.textColor = .black
        menuItemTitleLabel.font = Text.style9.font
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        contentView.backgroundColor = selected ? .mainPurple : .primary
    }
    
    func updateCell(with data: DrawerOption) {
        menuItemTitleLabel.text = data.title
    }
}
