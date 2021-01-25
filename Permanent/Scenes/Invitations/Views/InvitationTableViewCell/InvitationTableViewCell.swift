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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        emailLabel.style(withFont: Text.style8.font, textColor: .textPrimary, text: "Kevin Bacon")
        nameLabel.style(withFont: Text.style3.font, textColor: .primary, text: "kevin.bacon@gmail.com")
        
        resendButton.configureActionButtonUI(title: .resend)
        revokeButton.configureActionButtonUI(title: .revoke, bgColor: .destructive)
    }

    // MARK: - Actions
    
    
    @IBAction func resendAction(_ sender: UIButton) {
    }
    
    @IBAction func revokeAction(_ sender: UIButton) {
    }
    
}
