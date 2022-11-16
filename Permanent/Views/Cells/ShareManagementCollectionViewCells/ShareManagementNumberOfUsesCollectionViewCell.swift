//
//  ShareManagementNumberOfUsesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementNumberOfUsesCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementNumberOfUsesCollectionViewCell"
    
    @IBOutlet weak var maxUsesLabel: UITextField!
    @IBOutlet weak var additionalInformationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        maxUsesLabel.font = Text.style39.font
        maxUsesLabel.textColor = .darkBlue
        maxUsesLabel.backgroundColor = .whiteGray
        
        additionalInformationLabel.font = Text.style38.font
        additionalInformationLabel.textColor = .middleGray
    }
    
    func configure() {
        maxUsesLabel.text = "Max number of uses (optional)".localized()
        additionalInformationLabel.text = "The link will disappear after this number of uses has been reached.".localized()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
