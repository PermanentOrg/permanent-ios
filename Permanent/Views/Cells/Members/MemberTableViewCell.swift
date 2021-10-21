//  
//  MemberTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class MemberTableViewCell: UITableViewCell {
    fileprivate var nameLabel: UILabel!
    fileprivate var statusLabel: UILabel!
    fileprivate var emailLabel: UILabel!
    var editButton: BigAreaButton!
    
    var member: Account? {
        didSet {
            nameLabel.text = member?.name
            emailLabel.text = member?.email
            
            statusLabel.text = member?.status.value.parenthesized()
            statusLabel.isHidden = member?.status != .pending
            editButton.isHidden = member?.accessRole == .owner
        }
    }
    
    var editButtonAction: ((MemberTableViewCell) -> Void)?
    
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
        
        statusLabel = UILabel()
        statusLabel.textColor = .textPrimary
        statusLabel.font = Text.style12.font
        
        let hStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        hStack.spacing = 10
        
        emailLabel = UILabel()
        emailLabel.textColor = .textPrimary
        emailLabel.font = Text.style8.font
        
        let vStack = UIStackView(arrangedSubviews: [hStack, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 0
        vStack.alignment = .leading
        
        contentView.addSubview(vStack)
        vStack.enableAutoLayout()
        
        editButton = BigAreaButton(type: .custom)
        editButton.setImage(UIImage(named: "more"), for: .normal)
        editButton.tintColor = .lightGray
        editButton.setFont(Text.style11.font)
        editButton.enableAutoLayout()
        contentView.addSubview(editButton)
        
        editButton.addTarget(self, action: #selector(editButtonPressed(_:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo:contentView.leadingAnchor, constant: 20),
            vStack.rightAnchor.constraint(equalTo: editButton.leftAnchor, constant: -10),
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            editButton.heightAnchor.constraint(equalToConstant: 30),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    @objc func editButtonPressed(_ sender: Any) {
        editButtonAction?(self)
    }

}
