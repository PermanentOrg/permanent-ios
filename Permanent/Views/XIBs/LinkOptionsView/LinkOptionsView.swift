//  
//  LinkOptionsView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 03.12.2020.
//

import UIKit

protocol LinkOptionsViewDelegate: class {
    func copyLinkAction()
    func manageLinkAction()
    func revokeLinkAction()
}

class LinkOptionsView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var linkTextField: LinkTextField!
    @IBOutlet var copyLinkButton: RoundedButton!
    @IBOutlet var manageLinkButton: RoundedButton!
    @IBOutlet var revokeLinkButton: RoundedButton!
    
    weak var delegate: LinkOptionsViewDelegate?
    
    var link: String? {
        didSet {
            linkTextField.placeholder = link
        }
    }
    
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
    }
    
    func configureButtons(withData data: [(String, UIColor)]) {
        
        guard
            let buttons = [copyLinkButton, manageLinkButton, revokeLinkButton] as? [RoundedButton],
            data.count == buttons.count else { return }
        
        for (index, buttonData) in data.enumerated() {
            styleButton(buttons[index], withData: buttonData)
        }
    }
    
    fileprivate func styleButton(_ button: RoundedButton, withData data: (String, UIColor)) {
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
        button.setTitle(data.0, for: [])
        button.bgColor = data.1
    }
    
    @IBAction func copyLinkAction(_ sender: UIButton) {
        delegate?.copyLinkAction()
    }
    
    @IBAction func manageLinkAction(_ sender: UIButton) {
        delegate?.manageLinkAction()
    }
    
    @IBAction func revokeLinkAction(_ sender: UIButton) {
        delegate?.revokeLinkAction()
    }
}
