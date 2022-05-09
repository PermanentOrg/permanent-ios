//
//  EmptyFolderView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import UIKit

class EmptyFolderView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var emptyFolderLabel: UILabel!
    @IBOutlet var emptyImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    convenience init(title: String, image: UIImage, positionOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)) {
        self.init(frame: .zero)
        
        commonInit(positionOffset: positionOffset)
        
        emptyFolderLabel.text = title
        emptyImageView.image = image
    }
    
    private func commonInit(positionOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)) {
        loadNib()
        setupView(contentView, positionOffset: positionOffset)
        
        emptyFolderLabel.font = Text.style8.font
        emptyFolderLabel.textColor = .textPrimary
    }
}
