//
//  ShareManagementSeparatorFooterCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.11.2022.
//

import UIKit

class ShareManagementSeparatorFooterCollectionViewCell: UICollectionReusableView {
    static let identifier = "ShareManagementSeparatorFooterCollectionViewCell"
    
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorView.backgroundColor = .galleryGray
    }
    
    func configure() {

    }
    
    override func prepareForReuse() {
        separatorView.backgroundColor = .galleryGray
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
