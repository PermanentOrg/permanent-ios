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
    @IBOutlet weak var menuChevronImageView: UIImageView!
    var isExpanded: Bool? = nil {
        didSet {
            updateCellChevron()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        selectionStyle = .none
    
        menuItemImageView.tintColor = .iconTintLight
        menuItemTitleLabel.textColor = .white
        menuItemTitleLabel.font = Text.style9.font
        menuChevronImageView.tintColor = .white
        
        NotificationCenter.default.addObserver(forName: SideMenuViewController.updateArchiveSettingsChevron, object: nil, queue: nil) { [self] notification in
            isExpanded?.toggle()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Configure the view for the selected state
        contentView.backgroundColor = selected ? .mainPurple : .primary
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Configure the view for the selected state
        contentView.backgroundColor = highlighted ? .mainPurple : .primary
    }
    
    func updateCell(with data: DrawerOption, isExpanded: Bool? = nil) {
        menuItemImageView.image = data.icon?.templated
        menuItemTitleLabel.text = data.title
        self.isExpanded = isExpanded
    }
    
    func updateCellChevron() {
        if let isExpanded = self.isExpanded {
            UIView.animate(withDuration: 0.1) {
                self.menuChevronImageView.alpha = 0.5
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.menuChevronImageView.image = isExpanded ? UIImage(named: "arrowUpMedium")?.templated : UIImage(named: "arrowDownMedium")?.templated
                    self.menuChevronImageView.alpha = 1
                }
            }
        }
    }
    
    override func prepareForReuse() {
        menuChevronImageView.image = nil
    }
}
