//
//  FileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 04/12/2020.
//

import UIKit

class ArchiveTableViewCell: UITableViewCell {
    @IBOutlet var archiveNameLabel: UILabel!
    @IBOutlet var relationshipLabel: UILabel!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var archiveImageView: UIImageView!

    var rightButtonTapAction: CellButtonTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    private func configureUI() {
        archiveNameLabel.font = Text.style11.font
        archiveNameLabel.textColor = .textPrimary
        relationshipLabel.font = Text.style12.font
        relationshipLabel.textColor = .textPrimary
        archiveImageView.clipsToBounds = true
        
        moreButton.tintColor = .middleGray
        archiveImageView.backgroundColor = .primary
        
        // TEST
        archiveNameLabel.text = "The Johnny Williams Archive"
        relationshipLabel.text = "Friend"
    }
    
    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
}
