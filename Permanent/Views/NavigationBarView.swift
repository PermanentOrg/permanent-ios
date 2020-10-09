//
//  NavigationBarView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//

import UIKit

protocol NavigationBarViewDelegate: class {
    func didTapLeftButton()
}

class NavigationBarView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leftButton: UIButton!
    
    weak var delegate: NavigationBarViewDelegate?
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var icon: UIImage? {
        didSet {
            leftButton.setImage(icon, for: [])
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
        
        leftButton.tintColor = .white
    }
    
    // MARK: - Actions
    
    @IBAction func leftButtonAction(_ sender: UIButton) {
        delegate?.didTapLeftButton()
    }
    
}
