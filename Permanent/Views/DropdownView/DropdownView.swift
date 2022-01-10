//  
//  DropdownView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 04.01.2021.
//

import UIKit

class DropdownView: UIView {
    @IBOutlet fileprivate var contentView: UIView!
    @IBOutlet fileprivate var valueLabel: UILabel!
    @IBOutlet fileprivate var arrowImage: UIImageView!
    
    var value: String? {
        didSet {
            valueLabel.text = value
        }
    }
    
    var dropdownAction: ButtonAction?
    
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
        
        backgroundColor = .galleryGray
        valueLabel.textColor = .dustyGray
        valueLabel.font = Text.style4.font
        
        arrowImage.contentMode = .scaleAspectFit
        arrowImage.image = .expand

        clipsToBounds = true
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.doveGray.cgColor

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapAction(_:)))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    fileprivate func tapAction(_ selector: UITapGestureRecognizer) {
        rotateImage(upwards: true)
        dropdownAction?()
    }
    
    func rotateImage(upwards: Bool) {
        if upwards {
            arrowImage.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        } else {
            arrowImage.transform = CGAffineTransform.identity
        }
    }
}
