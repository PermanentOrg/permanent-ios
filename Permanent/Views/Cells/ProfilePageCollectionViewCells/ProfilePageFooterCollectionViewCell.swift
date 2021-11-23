//
//  ProfilePageFooterCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2021.
//

import UIKit

class ProfilePageFooterCollectionViewCell: UICollectionReusableView {

    static let identifier = "ProfilePageFooterCollectionViewCell"
    
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var readMoreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lineView.backgroundColor = .galleryGray

        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
    }
    
    func configure(isReadMoreButtonHidden: Bool = false, isBottomLineHidden: Bool = false) {
        readMoreButton.isHidden = isReadMoreButtonHidden
        lineView.isHidden = isBottomLineHidden
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

}
