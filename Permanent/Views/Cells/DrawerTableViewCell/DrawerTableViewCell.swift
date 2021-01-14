//  
//  DrawerTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit

class DrawerTableViewCell: UITableViewCell {
    @IBOutlet var menuItemImageView: UIImageView!
    @IBOutlet var menuItemTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        selectionStyle = .none
    
        menuItemImageView.tintColor = .iconTintLight
        menuItemTitleLabel.textColor = .white
        menuItemTitleLabel.font = Text.style9.font
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        contentView.backgroundColor = selected ? .mainPurple : .primary
    }
    
    func updateCell(with data: DrawerOption) {
        menuItemImageView.image = data.icon?.templated
        menuItemTitleLabel.text = data.title
    }
}
