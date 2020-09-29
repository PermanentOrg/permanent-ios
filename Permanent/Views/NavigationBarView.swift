//
//  NavigationBarView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit

class NavigationBarView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leftIconView: UIImageView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var icon: UIImage? {
        didSet {
            leftIconView.image = icon
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

    private func commonInit() {
        Bundle.main.loadNibNamed("NavigationBarView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.backgroundColor = .secondary
        
        titleLabel.textColor = .white
        titleLabel.font = Text.style9.font
        
        leftIconView.tintColor = .white
    }
}
