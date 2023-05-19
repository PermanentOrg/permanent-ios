//
//  LegacyPlanningSetUpButton.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.05.2023.
//
import UIKit

class LegacyPlanningSetUpButton: UIButton {
    let leftSideLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkBlue
        label.font = TextFontStyle.style35.font
        label.textAlignment = .center
        return label
    }()
    
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
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 8
        self.layer.backgroundColor = UIColor.white.cgColor
        self.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(leftSideLabel)
        
        NSLayoutConstraint.activate([
            leftSideLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            leftSideLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            leftSideLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 24)
        ])
    }
    
    private func updateBackgroundColor() {
            self.layer.backgroundColor = UIColor.white.cgColor
    }
}
