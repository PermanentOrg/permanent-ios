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
    
    @IBOutlet weak var nicknameTitleLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    @IBOutlet weak var genderTitleLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    
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
        
        nicknameTitleLabel.text = "Nickname".localized()
        nicknameTitleLabel.textColor = .darkGray
        nicknameTitleLabel.font = Text.style12.font
        
        genderTitleLabel.text = "Gender".localized()
        genderTitleLabel.textColor = .darkGray
        genderTitleLabel.font = Text.style12.font
        
        birthDateTitleLabel.text = "Birth Date".localized()
        birthDateTitleLabel.textColor = .darkGray
        birthDateTitleLabel.font = Text.style12.font
        
        birthLocationTitleLabel.text = "Birth Location".localized()
        birthLocationTitleLabel.textColor = .darkGray
        birthLocationTitleLabel.font = Text.style12.font
        
        fullNameLabel.textColor = .black
        fullNameLabel.font = Text.style13.font
        
        nicknameLabel.textColor = .black
        nicknameLabel.font = Text.style13.font
        
        genderLabel.textColor = .black
        genderLabel.font = Text.style13.font
        
        birthDateLabel.textColor = .black
        birthDateLabel.font = Text.style13.font
        
        birthLocationLabel.textColor = .black
        birthLocationLabel.font = Text.style13.font
    }
    
    func configure(fullName: String?, nickname: String?, gender: String?, birthDate: String?, birthLocation: String?) {
        if let fullNameValue = fullName,
            fullNameValue.isNotEmpty {
            fullNameLabel.text = fullNameValue
        } else {
            fullNameLabel.text = "Full name".localized()
        }
        
        if let nicknameValue = nickname,
           nicknameValue.isNotEmpty {
            nicknameLabel.text = nicknameValue
        } else {
            nicknameLabel.text = "Aliases or nicknames".localized()
        }
        
        if let genderValue = gender,
            genderValue.isNotEmpty {
            genderLabel.text = genderValue
        } else {
            genderLabel.text = "Gender"
        }
        
        if let birthDateValue = birthDate,
            birthDateValue.isNotEmpty {
            birthDateLabel.text = birthDateValue
        } else {
            birthDateLabel.text = "YYYY-MM-DD"
        }
        
        if let birthLocationValue = birthLocation,
            birthLocationValue.isNotEmpty {
            birthLocationLabel.text = birthLocationValue
        } else {
            birthLocationLabel.text = "Choose a location".localized()
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
