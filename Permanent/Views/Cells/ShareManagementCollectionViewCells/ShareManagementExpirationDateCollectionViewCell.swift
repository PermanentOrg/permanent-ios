//
//  ShareManagementExpirationDateCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementExpirationDateCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementExpirationDateCollectionViewCell"
    
    @IBOutlet weak var expirationDateField: UITextField!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expirationDateField.font = Text.style39.font
        expirationDateField.textColor = .darkBlue
        expirationDateField.backgroundColor = .whiteGray
        
        detailsLabel.font = Text.style38.font
        detailsLabel.textColor = .middleGray
    }
    
    func configure() {
        let placeholder = NSMutableAttributedString(string: "Expiration date (optional)".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkBlue])
        placeholder.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], range: (placeholder.string as NSString).range(of: "(optional)".localized()))
        expirationDateField.attributedPlaceholder = placeholder
        detailsLabel.text = "The link will disappear after this number of uses has been reached.".localized()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
