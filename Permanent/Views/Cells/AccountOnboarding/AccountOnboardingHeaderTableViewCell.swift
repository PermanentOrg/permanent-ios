//
//  AccountOnboardingHeaderTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.05.2022.
//

import UIKit

class AccountOnboardingHeaderTableViewCell: UITableViewHeaderFooterView {
    static let identifier = "AccountOnboardingHeaderTableViewCell"
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(label: String) {
        headerLabel.font = Text.style32.font
        headerLabel.textColor = .black
        headerLabel.text = label.localized()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
