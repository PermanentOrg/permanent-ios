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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(String(describing: EmptyFolderView.self), owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        emptyFolderLabel.text = .emptyFolderMessage
        emptyFolderLabel.font = Text.style16.font
        emptyFolderLabel.textColor = .lightGray
    }
}
