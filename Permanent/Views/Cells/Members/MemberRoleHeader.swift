//  
//  MemberRoleHeader.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15.12.2020.
//

import UIKit

class MemberRoleHeader: UIView {
    fileprivate var roleLabel: UILabel!
    fileprivate var infoButton: UIButton!
    fileprivate var tooltipText: String = ""
    
    fileprivate var infoAction: TooltipAction?
    
    convenience init(role: String, tooltipText: String, action: TooltipAction? = nil) {
        self.init(frame: .zero)
        
        configureUI()
        self.tooltipText = tooltipText
        self.infoAction = action
        roleLabel.text = role
    }
    
    fileprivate func configureUI() {
        backgroundColor = .backgroundPrimary
        
        roleLabel = UILabel()
        roleLabel.font = Text.style3.font
        roleLabel.textColor = .primary
        
        infoButton = UIButton()
        infoButton.setImage(UIImage.info.original, for: [])
        infoButton.imageView?.contentMode = .scaleAspectFit
        infoButton.addTarget(self, action: #selector(showInfoAction(_:)), for: .touchUpInside)
        
        addSubview(roleLabel)
        addSubview(infoButton)
        
        roleLabel.enableAutoLayout()
        infoButton.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            roleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            roleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            roleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            infoButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            infoButton.leadingAnchor.constraint(equalTo: roleLabel.trailingAnchor, constant: 5)
        ])
        
        infoButton.constraintToSquare(16)
    }
    
    @objc
    func showInfoAction(_ sender: UIButton) {

        // This view is used as a UITableViewHeader, so its parent is a UITableView.
        // In order to access the parent UIViewController, we access the superview's superview.
        
        let originX = sender.frame.origin.x + sender.frame.width + 3
        let originY = sender.frame.origin.y - sender.frame.height / 2
        
        let absPos = self.convert(CGPoint(x: originX, y: originY),
                                  to: self.superview?.superview)
        
        infoAction?(absPos, tooltipText)
    }
}
