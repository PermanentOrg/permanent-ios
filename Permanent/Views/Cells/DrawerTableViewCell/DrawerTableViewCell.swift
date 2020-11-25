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
        
        //contentView.backgroundColor = .primary
        
        menuItemImageView.image = .delete
        
        menuItemTitleLabel.textColor = .white
        menuItemTitleLabel.font = Text.style9.font
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            contentView.backgroundColor = .mainPurple
        } else {
            contentView.backgroundColor = .primary
        }
    }
    
}
