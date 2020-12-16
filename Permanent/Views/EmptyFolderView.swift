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
    
    convenience init(title: String, image: UIImage) {
        self.init(frame: .zero)
        
        commonInit()
        
        emptyFolderLabel.text = title
        emptyImageView.image = image
    }
    
    private func commonInit() {
        loadNib()
        setupView(contentView)
        
        emptyFolderLabel.font = Text.style8.font
        emptyFolderLabel.textColor = .textPrimary
    }
}
