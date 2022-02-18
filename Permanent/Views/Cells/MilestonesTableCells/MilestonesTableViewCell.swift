//
//  MilestonesTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.02.2022.
//
import UIKit

class MilestonesTableViewCell: UITableViewCell {

    @IBOutlet weak var milestoneTitleLabel: UILabel!
    @IBOutlet weak var milestoneLocationLabel: UILabel!
    @IBOutlet weak var milestoneDateLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    var moreButtonAction: ((MilestonesTableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        moreButton.setTitle("", for: .normal)
        let image = UIImage(named: "more")?.templated
        moreButton.setImage(image, for: .normal)
        moreButton.tintColor = .darkBlue
        
        milestoneTitleLabel.textColor = .primary
        milestoneTitleLabel.font = Text.style32.font
        milestoneTitleLabel.text = "Title".localized()
        
        milestoneLocationLabel.textColor = .lightGray
        milestoneLocationLabel.font = Text.style11.font
        milestoneLocationLabel.text = "Location not set".localized()
        
        milestoneDateLabel.textColor = .lightGray
        milestoneDateLabel.font = Text.style11.font
        milestoneDateLabel.text = "Start date".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(milestone: MilestoneProfileItem?) {
        milestoneTitleLabel.text = milestone?.title
        
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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        milestoneTitleLabel.text = "Title".localized()
        milestoneLocationLabel.text = "Location not set".localized()
        milestoneDateLabel.text = "Start date".localized()
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        moreButtonAction?(self)
    }
}
