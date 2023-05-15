//
//  ProfilePageAboutCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageAboutCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageAboutCollectionViewCell"
    
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentLabel.text = ""
        contentLabel.textColor = .middleGray
        contentLabel.font = TextFontStyle.style8.font
    }
    
    func configure(_ text: String?) {
        contentLabel.text = text
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(withText text: String?, collectionView: UICollectionView) -> CGSize {
        let currentText: NSAttributedString = NSAttributedString(string: text ?? "", attributes: [NSAttributedString.Key.font: TextFontStyle.style8.font as Any])
        let textHeight = currentText.boundingRect(with: CGSize(width: collectionView.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height.rounded(.up)

        return CGSize(width: collectionView.bounds.width, height: textHeight + 20)
    }
}
