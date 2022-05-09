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
    
    func configure(milestone: MilestoneProfileItem?, editMode: Bool) {
        if let title = milestone?.title {
            milestoneTitleLabel.textColor = .primary
            milestoneTitleLabel.text = title
        }
        
        if let location = milestone?.locationFormated {
            milestoneLocationLabel.textColor = .primary
            milestoneLocationLabel.text = location
        } else if !editMode {
            milestoneLocationLabel.text = nil
        }
        
        if let startDate = milestone?.startDateString {
            milestoneDateLabel.text = startDate
        }
        
        if let endDate = milestone?.endDateString {
            milestoneDateLabel.text?.append(" - \(endDate)")
        }
        
        if let description = milestone?.description {
            milestoneTextLabel.textColor = .darkGray
            milestoneTextLabel.text = description
        } else if !editMode {
            milestoneTextLabel.text = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        milestoneTitleLabel.text = "Title".localized()
        milestoneLocationLabel.text = "Location not set".localized()
        milestoneDateLabel.text = "Start date".localized()
        milestoneTextLabel.text = "Description".localized()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(withTitleText titleText: String?, withDescriptionText descriptionText: String?, withDateText dateText: String?, withLocationText locationText: String?, isEditEnabled: Bool,  collectionView: UICollectionView) -> CGSize {
        var fieldHeight: CGFloat = 0
        let horizontalMargin: CGFloat = 40
        let verticalMargin: CGFloat = 20
        
        let currentTitleText: NSAttributedString = NSAttributedString(string: titleText ?? "", attributes: [NSAttributedString.Key.font: Text.style32.font as Any])
        let currentDescriptionText: NSAttributedString = NSAttributedString(string: descriptionText ?? "", attributes: [NSAttributedString.Key.font: Text.style12.font as Any])
        
        let maxTitleHeight: CGFloat = 54 // Equivalent of 2 rows
        let titleTextHeight = currentTitleText.boundingRect(with: CGSize(width: collectionView.bounds.width - horizontalMargin, height: maxTitleHeight), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height.rounded(.up)
        
        let descriptionTextHeight = currentDescriptionText.boundingRect(with: CGSize(width: collectionView.bounds.width - horizontalMargin, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height.rounded(.up)
        
        fieldHeight += titleTextHeight
        
        let dateLocationHeight: CGFloat = 21
        if isEditEnabled {
            fieldHeight += 2 * dateLocationHeight
            fieldHeight += descriptionTextHeight
        } else {
            if let descriptionText = descriptionText, descriptionText != "Description".localized() {
                fieldHeight += descriptionTextHeight
            }
            
            if let dateText = dateText, dateText != "Start date".localized() {
                fieldHeight += dateLocationHeight
            }
            if let locationText = locationText, locationText != "Location not set".localized() {
                fieldHeight += dateLocationHeight
            }
        }
        
        return CGSize(width: collectionView.bounds.width, height: fieldHeight + verticalMargin)
    }
}
