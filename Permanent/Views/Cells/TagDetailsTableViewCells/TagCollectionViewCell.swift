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
      
    func configure(name: String, isVisible: Bool = false, font: UIFont = Text.style2.font, fontColor: UIColor = .black, cornerRadius: CGFloat = 10.0) {
        checkMarkImage.isHidden = !isVisible
        checkMarkImage.tintColor = .black
        
        setBackgroudColor()
        tagBackgroundView.tintColor = .white
        tagBackgroundView.layer.cornerRadius = cornerRadius
        
        tagLabel.textColor = fontColor
        tagLabel.font = font
        tagLabel.text = name
    }
    
    func setBackgroudColor(color: UIColor = .white) {
        self.tagBackgroundView.backgroundColor = color
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
