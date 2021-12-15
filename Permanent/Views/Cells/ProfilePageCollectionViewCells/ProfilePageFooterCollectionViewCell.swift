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
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Read Less".localized(), attributes: [.font: Text.style16.font, .foregroundColor: UIColor.darkGray]), for: .normal)
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Read Less".localized(), attributes: [.font: Text.style16.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
        } else {
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style16.font, .foregroundColor: UIColor.darkGray]), for: .normal)
            readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style16.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
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
