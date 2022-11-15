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
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
