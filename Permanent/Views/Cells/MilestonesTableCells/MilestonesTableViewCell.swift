//
//  MilestonesTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.02.2022.
//
import UIKit

class MilestonesTableViewCell: UITableViewCell {

    @IBOutlet weak var milestoneTitleLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    var moreButtonAction: ((MilestonesTableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        moreButton.setTitle("", for: .normal)
        let image = UIImage(named: "more")?.templated
        moreButton.setImage(image, for: .normal)
        moreButton.tintColor = .darkBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        moreButtonAction?(self)
    }
    
}
