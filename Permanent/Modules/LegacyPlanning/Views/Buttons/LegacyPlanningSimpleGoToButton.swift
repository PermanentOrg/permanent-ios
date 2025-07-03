//
//  LegacyPlanningSimpleGoToButton.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.06.2025.

import UIKit

class LegacyPlanningSimpleGoToButton: UIButton {
    let textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = TextFontStyle.style35.font
        label.textAlignment = .left
        return label
    }()
    
    var isSelectable: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.7)
            } else {
                updateBackgroundColor()
            }
        }
    }
    
    override init(frame: CGRect) {
        self.isSelectable = false
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.isSelectable = false
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 8
        self.layer.backgroundColor = UIColor.lightGray.cgColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = false
        
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0)
        ])
    }
    
    private func updateBackgroundColor() {
        if isSelectable {
            self.layer.backgroundColor = UIColor.darkBlue.cgColor
            self.isUserInteractionEnabled = true
        } else {
            self.layer.backgroundColor = UIColor.lightGray.cgColor
            self.isUserInteractionEnabled = false
        }
    }
}

