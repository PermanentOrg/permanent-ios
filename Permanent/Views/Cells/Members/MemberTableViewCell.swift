//  
//  MemberTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class MemberTableViewCell: UITableViewCell {
    fileprivate var nameLabel: UILabel!
    fileprivate var emailLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureUI() {
        
        nameLabel = UILabel()
        nameLabel.textColor = .primary
        nameLabel.font = Text.style11.font
        
        emailLabel = UILabel()
        emailLabel.textColor = .textPrimary
        emailLabel.font = Text.style8.font
        
        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 0
        
        self.addSubview(vStack)
        vStack.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    func updateCell() {
        nameLabel.text = "Mike Johnson"
        emailLabel.text = "mike.johnson@apple.com"
    }
}
