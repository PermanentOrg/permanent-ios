//
//  FileCollectionViewHeaderCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.03.2023.
//

import UIKit

class FileCollectionViewHeaderCell: UICollectionReusableView {
    static let identifier = "FileCollectionViewHeaderCell"
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    var leftButtonAction: ((UICollectionReusableView) -> Void)?
    var rightButtonAction: ((UICollectionReusableView) -> Void)?
    var clearButtonAction: ((UICollectionReusableView) -> Void)?
    
    var leftButtonTitle: String? {
        didSet {
            leftButton.setTitle(leftButtonTitle, for: .normal)
        }
    }
    
    var rightButtonTitle: String? {
        didSet {
            rightButton.setTitle(rightButtonTitle, for: .normal)
        }
    }
    
    var rightButtonImageIsVisible: Bool? {
        didSet {
            if let rightButtonImageIsVisible = rightButtonImageIsVisible, rightButtonImageIsVisible {
                let image = UIImage(named: "checkbox")?.templated
                rightButton.setImage(image, for: .normal)
                rightButton.tintColor = .darkBlue
            } else {
                rightButton.setImage(nil, for: .normal)
            }
        }
    }
    
    var clearButtonIsVisible: Bool? {
        didSet {
            if let cancelButtonIsVisible = clearButtonIsVisible, cancelButtonIsVisible {
                clearButton.isHidden = false
            } else {
                clearButton.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftButton.setFont(Text.style34.font)
        leftButton.setTitleColor(.lightGray, for: [])
        
        clearButton.setTitle("Clear".localized(), for: .normal)
        clearButton.setFont(Text.style34.font)
        clearButton.setTitleColor(.paleRed, for: [])
        clearButton.isHidden = true
        
        rightButton.setFont(Text.style34.font)
        rightButton.setTitleColor(.darkBlue, for: [])
        
        rightButton.semanticContentAttribute = .forceRightToLeft
        rightButton.imageView?.contentMode = .scaleAspectFit
    }
    
    @IBAction func leftButtonPressed(_ sender: Any) {
        leftButtonAction?(self)
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        clearButtonAction?(self)
    }
    
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
