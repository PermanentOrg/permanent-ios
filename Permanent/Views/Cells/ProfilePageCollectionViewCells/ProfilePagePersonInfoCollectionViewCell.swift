//
//  ProfilePagePersonInfoCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePagePersonInfoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var fullNameTitleLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var birthDateTitleLabel: UILabel!
    @IBOutlet weak var birthDateLabel: UILabel!
    @IBOutlet weak var birthLocationTitleLabel: UILabel!
    @IBOutlet weak var birthLocationLabel: UILabel!
    
    static let identifier = "ProfilePagePersonInfoCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        fullNameTitleLabel.text = "Full Name".localized()
        fullNameTitleLabel.textColor = .darkGray
        fullNameTitleLabel.font = Text.style12.font
        
        birthDateTitleLabel.text = "Birth Date".localized()
        birthDateTitleLabel.textColor = .darkGray
        birthDateTitleLabel.font = Text.style12.font
        
        birthLocationTitleLabel.text = "Birth Location".localized()
        birthLocationTitleLabel.textColor = .darkGray
        birthLocationTitleLabel.font = Text.style12.font
        
        fullNameLabel.text = ""
        fullNameLabel.textColor = .primary
        fullNameLabel.font = Text.style13.font
        
        birthDateLabel.text = ""
        birthDateLabel.textColor = .primary
        birthDateLabel.font = Text.style13.font
        
        birthLocationLabel.text = ""
        birthLocationLabel.textColor = .primary
        birthLocationLabel.font = Text.style13.font
        
        fullNameLabel.text = "User Name"
        birthDateLabel.text = "Jan 01, 2000"
        birthLocationLabel.text = "1401 South Grand Avenue, Los Angeles, California, United States"
    }
    
    func configure(fullName: String = "", birthDate: String = "", birthLocation: String = "") {
        fullNameLabel.text = fullName.localized()
        birthDateLabel.text = birthDate
        birthLocationLabel.text = birthLocation
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
