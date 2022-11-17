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
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
