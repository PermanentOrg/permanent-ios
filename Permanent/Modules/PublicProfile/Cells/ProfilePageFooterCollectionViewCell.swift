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
    
    var readMoreIsEnabled = false
    
    var readMoreButtonAction: ButtonAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lineView.backgroundColor = .galleryGray

        updateButtonTitle()
    }
    
    func configure(isReadMoreButtonHidden: Bool = false, isBottomLineHidden: Bool = false, isReadMoreEnabled: Bool = false) {
        readMoreIsEnabled = isReadMoreEnabled
        readMoreButton.isHidden = isReadMoreButtonHidden
        lineView.isHidden = isBottomLineHidden
        updateButtonTitle()
    }
    
    func updateButtonTitle() {
        if readMoreIsEnabled {
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Show Less".localized(), attributes: [.font: TextFontStyle.style16.font, .foregroundColor: UIColor.darkBlue]), for: .normal)
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Show Less".localized(), attributes: [.font: TextFontStyle.style16.font, .foregroundColor: UIColor.lightBlue]), for: .highlighted)
        } else {
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Show More".localized(), attributes: [.font: TextFontStyle.style16.font, .foregroundColor: UIColor.darkBlue]), for: .normal)
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Show More".localized(), attributes: [.font: TextFontStyle.style16.font, .foregroundColor: UIColor.lightBlue]), for: .highlighted)
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func readMoreButtonAction(_ sender: Any) {
        readMoreButtonAction?()
        updateButtonTitle()
    }

}
