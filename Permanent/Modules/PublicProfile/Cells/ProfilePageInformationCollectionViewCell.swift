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
        titleLabel.font = TextFontStyle.style12.font
        
        contentLabel.textColor = .black
        contentLabel.font = TextFontStyle.style13.font
    }
    
    func configure(with content: String?, archiveType: ArchiveType?, cellType: ProfileCellType, isEditDataEnabled: Bool = true) {
        guard let archiveType = archiveType else {
            return
        }
        
        switch cellType {
        case .fullName:
            titleLabel.text = ProfilePageData.nameTitle(archiveType: archiveType)
            if let fullNameValue = content,
                fullNameValue.isNotEmpty {
                contentLabel.text = fullNameValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.nameHint(archiveType: archiveType) : ""
            }
            
        case .nickName:
            titleLabel.text = ProfilePageData.nickNameTitle(archiveType: archiveType)
            if let nicknameValue = content,
                nicknameValue.isNotEmpty {
                contentLabel.text = nicknameValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.nickNameHint(archiveType: archiveType) : ""
            }
            
        case .gender:
            titleLabel.text = ProfilePageData.genderTitle(archiveType: archiveType)
            if let genderValue = content,
                genderValue.isNotEmpty {
                contentLabel.text = genderValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.genderHint(archiveType: archiveType) : ""
            }
            
        case .birthDate:
            titleLabel.text = ProfilePageData.birthDateTitle(archiveType: archiveType)
            if let birthDateValue = content,
                birthDateValue.isNotEmpty {
                contentLabel.text = birthDateValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.birthDateHint(archiveType: archiveType) : ""
            }
            
        case .birthLocation:
            titleLabel.text = ProfilePageData.birthLocationTitle(archiveType: archiveType)
            if let birthLocationValue = content,
                birthLocationValue.isNotEmpty {
                contentLabel.text = birthLocationValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.birthLocationHint(archiveType: archiveType) : ""
            }
            
        case .establishedDate:
            titleLabel.text = ProfilePageData.birthDateTitle(archiveType: archiveType)
            if let birthDateValue = content,
                birthDateValue.isNotEmpty {
                contentLabel.text = birthDateValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.birthDateHint(archiveType: archiveType) : ""
            }
            
        case .establishedLocation:
            titleLabel.text = ProfilePageData.birthLocationTitle(archiveType: archiveType)
            if let birthLocationValue = content,
                birthLocationValue.isNotEmpty {
                contentLabel.text = birthLocationValue
            } else {
                contentLabel.text = isEditDataEnabled ? ProfilePageData.birthLocationHint(archiveType: archiveType) : ""
            }
            
        default:
            titleLabel.text = ""
            contentLabel.text = ""
        }
        
        if let content = content,
            content.isNotEmpty {
            contentLabel.textColor = .black
        } else {
            contentLabel.textColor = .darkGray
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}
