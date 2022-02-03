//
//  ProfilePageMilestonesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageMilestonesCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProfilePageMilestonesCollectionViewCell"
    
    @IBOutlet weak var milestoneTitleLabel: UILabel!
    @IBOutlet weak var milestoneLocationLabel: UILabel!
    @IBOutlet weak var milestoneDateLabel: UILabel!
    
    @IBOutlet weak var milestoneTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        milestoneTitleLabel.textColor = .lightGray
        milestoneTitleLabel.font = Text.style32.font
        milestoneTitleLabel.text = "Title".localized()
    
        milestoneLocationLabel.textColor = .lightGray
        milestoneLocationLabel.font = Text.style11.font
        milestoneLocationLabel.text = "Location not set".localized()
        
        milestoneDateLabel.textColor = .lightGray
        milestoneDateLabel.font = Text.style11.font
        milestoneDateLabel.text = "Start date".localized()
        
        milestoneTextLabel.textColor = .lightGray
        milestoneTextLabel.font = Text.style12.font
        milestoneTextLabel.text = "Description".localized()
    }
    
    func configure(milestone: MilestoneProfileItem?) {
        if let title = milestone?.title {
            milestoneTitleLabel.textColor = .primary
            milestoneTitleLabel.text = title
        }
        
        if let location = milestone?.locationFormated {
            milestoneLocationLabel.textColor = .primary
            milestoneLocationLabel.text = location
        }
        
        if let startDate = milestone?.startDate {
            milestoneDateLabel.text = startDate
        }
        
        if let endDate = milestone?.endDate {
            milestoneDateLabel.text?.append(" - \(endDate)")
        }
        
        if let description = milestone?.description {
            milestoneTextLabel.textColor = .darkGray
            milestoneTextLabel.text = description
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 130)
    }
}
