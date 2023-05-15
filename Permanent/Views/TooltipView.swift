//  
//  TooltipView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 16.12.2020.
//

import UIKit

class TooltipView: UIView {
    fileprivate var infoLabel: UILabel!
    
    var text: String? {
        didSet {
            infoLabel.text = text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configureUI()
    }
    
    convenience init(text: String) {
        self.init(frame: .zero)
        
        configureUI()
        infoLabel.text = text
    }
    
    fileprivate func configureUI() {
        backgroundColor = .middleGray
        
        infoLabel = UILabel()
        infoLabel.textColor = .galleryGray
        infoLabel.font = TextFontStyle.style8.font
        infoLabel.numberOfLines = 0
        
        addSubview(infoLabel)
        infoLabel.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            infoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }

}
