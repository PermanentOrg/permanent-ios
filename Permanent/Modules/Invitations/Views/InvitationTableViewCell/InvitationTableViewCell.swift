//  
//  InvitationTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.01.2021.
//

import UIKit

class InvitationTableViewCell: UITableViewCell {
    // MARK: - Properties
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var resendButton: RoundedButton!
    @IBOutlet var revokeButton: RoundedButton!
    
    var resendAction: ButtonAction?
    var revokeAction: ButtonAction?
    
    var invite: Invite? {
        didSet {
            nameLabel.text = invite?.name
            emailLabel.text = invite?.email
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        emailLabel.style(withFont: TextFontStyle.style8.font, textColor: .textPrimary, text: "Kevin Bacon")
        nameLabel.style(withFont: TextFontStyle.style3.font, textColor: .primary, text: "kevin.bacon@gmail.com")
        
        resendButton.configureActionButtonUI(title: .resend)
        revokeButton.configureActionButtonUI(title: .revoke, bgColor: .destructive)
    }

    // MARK: - Actions
    @IBAction func resendAction(_ sender: UIButton) {
        resendAction?()
    }
    
    @IBAction func revokeAction(_ sender: UIButton) {
        revokeAction?()
    }
}
