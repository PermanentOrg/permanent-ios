//
//  TagCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.04.2021.
//

import UIKit

class TagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tagBackgroundView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var checkMarkImage: UIImageView!
    
    static let identifier = "TagCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
      
    func configure(name: String, isChecked: Bool = false, font: UIFont = Text.style2.font, fontColor: UIColor = .black, cornerRadius: CGFloat = 10.0, backgroundColor: UIColor = .white) {
        checkMarkImage.isHidden = !isChecked
        checkMarkImage.tintColor = .black
        
        tagBackgroundView.backgroundColor = backgroundColor
        tagBackgroundView.tintColor = .white
        tagBackgroundView.layer.cornerRadius = cornerRadius
        
        tagLabel.textColor = fontColor
        tagLabel.font = font
        tagLabel.text = name
    }
}

extension TagCollectionViewCell: CollectionCellAutoLayout {
    var cachedSize: CGSize? {
        get {
            return frame.size
        }
        set {
        }
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return preferredLayoutAttributes(layoutAttributes)
    }
}
