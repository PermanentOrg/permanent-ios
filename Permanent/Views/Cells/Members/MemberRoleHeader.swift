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
    fileprivate var noDataHeader: UILabel!
    fileprivate var tooltipText: String = ""
    
    fileprivate var infoAction: TooltipAction?
    
    var isSectionEmpty: Bool = true {
        didSet {
            noDataHeader.isHidden = !isSectionEmpty
        }
    }
    
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
        
        let hStack = UIStackView(arrangedSubviews: [
            roleLabel,
            infoButton
        ])
        
        hStack.spacing = 5
        hStack.alignment = .center
        
        noDataHeader = UILabel()
        noDataHeader.text = String.none
        noDataHeader.textColor = .textPrimary
        noDataHeader.font = Text.style8.font
        
        let vStack = UIStackView(arrangedSubviews: [
            hStack,
            noDataHeader
        ])
        
        vStack.axis = .vertical
        vStack.spacing = 10
        vStack.alignment = .leading
        vStack.enableAutoLayout()
    
        addSubview(vStack)
        
        vStack.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
    }
    
    @objc
    func showInfoAction(_ sender: UIButton) {

        // This view is used as a UITableViewHeader, so its parent is a UITableView.
        // In order to access the parent UIViewController, we access the superview's superview.
        
        let originX = sender.frame.origin.x + sender.frame.width + 20 + 3 // leadingMargin + offset
        let originY = sender.frame.origin.y + 10 // topMargin
        
        let absPos = self.convert(CGPoint(x: originX, y: originY),
                                  to: self.superview?.superview)
        
        infoAction?(absPos, tooltipText)
    }
}
