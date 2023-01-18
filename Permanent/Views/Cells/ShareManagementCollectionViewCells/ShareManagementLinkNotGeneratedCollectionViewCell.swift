//
//  LinkNotGeneratedCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.11.2022.
//

import UIKit

class ShareManagementLinkNotGeneratedCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementLinkNotGeneratedCollectionViewCell"
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var createShareLinkButton: RoundedButton!
    
    var buttonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.image = UIImage(named: "shareManagementLink")
        imageView.contentMode = .scaleAspectFit
        
        createShareLinkButton.configureActionButtonUI(title: "Create share link".localized(),bgColor: .darkBlue)
        createShareLinkButton.setFont(Text.style8.font)
    }
    @IBAction func buttonAction(_ sender: Any) {
        buttonAction?()
    }
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
