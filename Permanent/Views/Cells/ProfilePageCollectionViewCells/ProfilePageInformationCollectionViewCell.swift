//
//  ProfilePageInformationCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.01.2022.
//

import UIKit

class ProfilePageInformationCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageInformationCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = .darkGray
        titleLabel.font = Text.style12.font
        
        contentLabel.textColor = .black
        contentLabel.font = Text.style13.font
    }
    
    func configure(with content: String?, archiveType: ArchiveType?, cellType: ProfileCellType) {
        guard let archiveType = archiveType else {
            return
        }
        
        switch cellType {
        case .fullName:
            titleLabel.text = nameTitle(archiveType: archiveType)
            if let fullNameValue = content,
               fullNameValue.isNotEmpty {
                contentLabel.text = fullNameValue
            } else {
                contentLabel.text = "Full name".localized()
            }
            
        case .nickName:
            titleLabel.text = nickNameTitle(archiveType: archiveType)
            if let nicknameValue = content,
               nicknameValue.isNotEmpty {
                contentLabel.text = nicknameValue
            } else {
                contentLabel.text = "Aliases or nicknames".localized()
            }
            
        case .gender:
            titleLabel.text = genderTitle(archiveType: archiveType)
            if let genderValue = content,
               genderValue.isNotEmpty {
                contentLabel.text = genderValue
            } else {
                contentLabel.text = "Gender"
            }
            
        case .birthDate:
            titleLabel.text = birthDateTitle(archiveType: archiveType)
            if let birthDateValue = content,
               birthDateValue.isNotEmpty {
                contentLabel.text = birthDateValue
            } else {
                contentLabel.text = "YYYY-MM-DD"
            }
            
        case .birthLocation:
            titleLabel.text = birthLocationTitle(archiveType: archiveType)
            if let birthLocationValue = content,
               birthLocationValue.isNotEmpty {
                contentLabel.text = birthLocationValue
            } else {
                contentLabel.text = "Choose a location".localized()
            }
            
        default:
            titleLabel.text = ""
            contentLabel.text = ""
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    private func nameTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Full Name".localized()
        case .family:
            return "Full Name"
        case .organization:
            return "Full Name"
        }
    }
    
    private func nickNameTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Nickname".localized()
        case .family:
            return "Nickname"
        case .organization:
            return "Nickname"
        }
    }
    
    private func genderTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Gender".localized()
        case .family:
            return ""
        case .organization:
            return ""
        }
    }
    
    private func birthDateTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Birth Date".localized()
        case .family:
            return ""
        case .organization:
            return ""
        }
    }
    
    private func birthLocationTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Birth Location".localized()
        case .family:
            return ""
        case .organization:
            return ""
        }
    }
}
