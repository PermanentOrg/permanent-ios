//
//  LegacyPlanButton.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.04.2023.
//

import Foundation
import UIKit

class LegacyPlanButton: UIButton {
    let label1: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let label2: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let imageIcon: UIImage = {
        let image = UIImage(named: "legacyPlanRightArrow")!
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(label1)
        addSubview(label2)
        
        NSLayoutConstraint.activate([
            label1.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label1.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label1.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            label2.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 8),
            label2.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label2.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label2.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}
