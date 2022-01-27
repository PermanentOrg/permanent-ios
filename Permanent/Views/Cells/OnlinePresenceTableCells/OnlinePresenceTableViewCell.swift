//
//  OnlinePresenceTableViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.01.2022.
//

import UIKit

class OnlinePresenceTableViewCell: UITableViewCell {
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var linkLabel: UILabel!
    
    var moreButtonAction: ((OnlinePresenceTableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        moreButton.setTitle("", for: .normal)
        let image = UIImage(named: "more")?.templated
        moreButton.setImage(image, for: .normal)
        moreButton.tintColor = .darkBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        moreButtonAction?(self)
    }
}
