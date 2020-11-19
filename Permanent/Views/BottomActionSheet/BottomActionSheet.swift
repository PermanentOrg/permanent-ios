//  
//  BottomActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 19.11.2020.
//

import UIKit

class BottomActionSheet: UIView {
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var actionButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    
    var closeAction: ButtonAction?
    var fileAction: ButtonAction?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    fileprivate func commonInit() {
        loadNib()
        setupView(contentView)
        
        contentView.backgroundColor = .backgroundPrimary
        
        closeButton.setTitleColor(.primary, for: [])
        closeButton.setTitle(.cancel, for: [])
        closeButton.setFont(Text.style11.font)
        
        actionButton.setTitleColor(.primary, for: [])
        actionButton.setFont(Text.style11.font)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        closeAction?()
    }
    
    @IBAction func fileActionButton(_ sender: UIButton) {
        fileAction?()
    }
    
    func setActionTitle(_ title: String) {
        actionButton.setTitle(title, for: [])
    }
    
}
