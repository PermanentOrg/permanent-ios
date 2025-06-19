//
//  EmptyFolderView.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import UIKit

class EmptyFolderView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var emptyFolderLabel: UILabel!
    @IBOutlet var emptyImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    convenience init(title: String, image: UIImage, positionOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)) {
        self.init(frame: .zero)
        
        commonInit(positionOffset: positionOffset)
        
        emptyFolderLabel.text = title
        emptyImageView.image = image
    }
    
    private func commonInit(positionOffset: CGPoint = CGPoint(x: 0.0, y: 0.0)) {
        loadNib()
        setupView(contentView, positionOffset: positionOffset)
        
        emptyFolderLabel.font = TextFontStyle.style8.font
        emptyFolderLabel.textColor = .textPrimary
        
        // Adjust image size for iPad to max 30% of screen width
        adjustImageSizeForDevice()
    }
    
    private func adjustImageSizeForDevice() {
        guard !Constants.Design.isPhone else { return }
        
        // On iPad, limit image to 30% of screen width
        let maxImageWidth = UIScreen.main.bounds.width * 0.3
        
        // Remove existing leading/trailing constraints from XIB
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Find and remove the existing leading/trailing constraints
        if let containerView = emptyImageView.superview {
            let constraintsToRemove = containerView.constraints.filter { constraint in
                (constraint.firstItem === emptyImageView && (constraint.firstAttribute == .leading || constraint.firstAttribute == .trailing)) ||
                (constraint.secondItem === emptyImageView && (constraint.secondAttribute == .leading || constraint.secondAttribute == .trailing))
            }
            containerView.removeConstraints(constraintsToRemove)
            
            // Add new constraints for iPad
            NSLayoutConstraint.activate([
                emptyImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                emptyImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxImageWidth),
                emptyImageView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.6) // Fallback constraint
            ])
        }
    }
}
