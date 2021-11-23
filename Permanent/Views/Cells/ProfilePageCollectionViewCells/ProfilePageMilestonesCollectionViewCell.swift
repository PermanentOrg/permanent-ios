//
//  ProfilePageMilestonesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageMilestonesCollectionViewCell: ProfilePageBaseCollectionViewCell {
    
    static let identifier = "ProfilePageMilestonesCollectionViewCell"
    
    @IBOutlet weak var milestoneTitleLabel: UILabel!
    @IBOutlet weak var milestoneLocationLabel: UILabel!
    @IBOutlet weak var milestoneDateLabel: UILabel!
    @IBOutlet weak var milestoneTextLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        milestoneTitleLabel.text = "Lizard Creek Hill"
        milestoneTitleLabel.textColor = .primary
        milestoneTitleLabel.font = Text.style32.font
        
        milestoneLocationLabel.text = "Johnson Township, IA, USA"
        milestoneLocationLabel.textColor = .primary
        milestoneLocationLabel.font = Text.style11.font
        
        milestoneDateLabel.text = "Jun 22, 2015"
        milestoneDateLabel.textColor = .lightGray
        milestoneDateLabel.font = Text.style11.font
        
        milestoneTextLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
        milestoneTextLabel.textColor = .darkGray
        milestoneTextLabel.font = Text.style12.font
        
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
