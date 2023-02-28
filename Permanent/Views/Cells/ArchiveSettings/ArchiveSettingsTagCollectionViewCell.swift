//
//  ArchiveSettingsTagCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.01.2023.
//

import UIKit

class ArchiveSettingsTagCollectionViewCell: UICollectionViewCell {
    static let identifier = "ArchiveSettingsTagCollectionViewCell"
    
    @IBOutlet weak var tagBackgroundView: UIView!
    @IBOutlet weak var tagNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var rightSideButton: UIButton!
    @IBOutlet weak var rightSideButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightSideButtonWidthConstraint: NSLayoutConstraint!
    
    var rightSideButtonAction: (() -> Void)?
    var editButtonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func initUI() {
        tagBackgroundView.backgroundColor = .tangerine
        tagBackgroundView.alpha = 0.25
        tagBackgroundView.layer.cornerRadius = 10
        
        tagNameLabel.font = Text.style39.font
        
        editButton.setImage(UIImage(named: "editBorder")?.withRenderingMode(.alwaysTemplate), for: .normal)
        editButton.tintColor = .darkBlue
        
        rightSideButton.setImage(UIImage(named: "deleteBorder")?.withRenderingMode(.alwaysTemplate), for: .normal)
        rightSideButton.tintColor = .paleRed
        
        rightSideButtonWidthConstraint.constant = 14
        rightSideButtonHeightConstraint.constant = 16
    }
    
    func configure(tagName: String?) {
        guard let tagName = tagName else {
            return
        }
        
        tagNameLabel.text = tagName
    }
    
    @IBAction func rightSideButtonAction(_ sender: Any) {
        rightSideButtonAction?()
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        editButtonAction?()
    }
    
}
