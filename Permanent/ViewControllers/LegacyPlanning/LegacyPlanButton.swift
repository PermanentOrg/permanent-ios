//
//  LegacyPlanButton.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.04.2023.
//

import UIKit

class LegacyPlanButton: UIButton {
    let leftSideLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = Text.style35.font
        label.textAlignment = .left
        return label
    }()
    
    let rightSideImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        
        addSubview(leftSideLabel)
        addSubview(rightSideImage)
        
        NSLayoutConstraint.activate([
            leftSideLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            leftSideLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            leftSideLabel.trailingAnchor.constraint(equalTo: rightSideImage.leadingAnchor, constant: 10),
            
            rightSideImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            rightSideImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            rightSideImage.heightAnchor.constraint(equalToConstant: 16),
            rightSideImage.widthAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func updateBackgroundColor() {
        if isSelectable {
            self.layer.backgroundColor = UIColor.darkBlue.cgColor
            self.isUserInteractionEnabled = true
        } else {
            // Set the disabled background color
            self.layer.backgroundColor = UIColor.lightGray.cgColor
            self.isUserInteractionEnabled = false
        }
    }
}

