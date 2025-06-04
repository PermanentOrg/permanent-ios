//
//  ProfilePageAboutCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageAboutCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageAboutCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textColor = .darkGray
        titleLabel.font = TextFontStyle.style12.font
        
        contentLabel.textColor = .black
        contentLabel.font = TextFontStyle.style13.font
    }
    
    func configure(_ title: String?, _ text: String?) {
        titleLabel.text = title
        contentLabel.text = text
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(withTitle title: String?, withText text: String?, collectionView: UICollectionView) -> CGSize {
        // Calculate the width available for text (collection view width minus 20pt margins on each side)
        let availableWidth = collectionView.bounds.width - 40
        
        // Create attributed strings with the actual fonts used in the cell
        let titleAttributedString = NSAttributedString(
            string: title ?? "", 
            attributes: [NSAttributedString.Key.font: TextFontStyle.style12.font as Any]
        )
        let contentAttributedString = NSAttributedString(
            string: text ?? "", 
            attributes: [NSAttributedString.Key.font: TextFontStyle.style13.font as Any]
        )
        
        // Calculate height for title text
        let titleHeight = titleAttributedString.boundingRect(
            with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height.rounded(.up)
        
        // Calculate height for content text
        let contentHeight = contentAttributedString.boundingRect(
            with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height.rounded(.up)
        
        // Total height = title height + content height + vertical margins (10 + 5 + 10 = 25pt)
        var totalHeight = titleHeight + contentHeight + 15
        
        return CGSize(width: collectionView.bounds.width, height: totalHeight)
    }
    
    // Keep the old method for backward compatibility
    static func size(withText text: String?, collectionView: UICollectionView) -> CGSize {
        return size(withTitle: "Purpose", withText: text, collectionView: collectionView)
    }
}
