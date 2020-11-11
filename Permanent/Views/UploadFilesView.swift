//
//  UploadFilesView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 20/10/2020.
//

import UIKit

class UploadFilesView: UIView {
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
        Bundle.main.loadNibNamed(String(describing: UploadFilesView.self), owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        emptyFolderLabel.text = .uploadFilesMessage
        emptyFolderLabel.font = Text.style13.font
        emptyFolderLabel.textColor = .primary
    }
}
