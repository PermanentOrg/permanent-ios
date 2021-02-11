//
//  ArchiveTableViewCell.swift
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
    @IBOutlet var approveButton: RoundedButton!
    @IBOutlet var denyButton: RoundedButton!
    @IBOutlet var bottomButtonsView: UIStackView!
    
    var rightButtonTapAction: CellButtonTapAction?
    var approveAction: ButtonAction?
    var denyAction: ButtonAction?
    
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
        
        approveButton.configureActionButtonUI(title: .approve)
        denyButton.configureActionButtonUI(title: .deny, bgColor: .destructive)
    }
    
    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
    
    func updateCell(model: MinArchiveVO) {
        archiveImageView.load(urlString: model.thumbnail)
        archiveNameLabel.text = String.init(format: .archiveName, model.name)
        relationshipLabel.text = "Friend" // TODO
        
        bottomButtonsView.isHidden = ShareStatus.status(forValue: model.shareStatus) != .pending
        
    }
    
    func hideBottomButtons(status: Bool ) {
        self.bottomButtonsView.isHidden = status
    }
    
    @IBAction func approveAction(_ sender: UIButton) {
        approveAction?()
    }
    
    @IBAction func denyAction(_ sender: UIButton) {
        denyAction?()
    }
}
