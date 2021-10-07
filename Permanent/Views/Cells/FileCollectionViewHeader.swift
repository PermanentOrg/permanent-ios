//
//  FileCollectionViewHeader.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 07.10.2021.
//

import UIKit

class FileCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var leftButtonAction: ((UICollectionReusableView) -> Void)?
    var rightButtonAction: ((UICollectionReusableView) -> Void)?
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftButton.setFont(Text.style11.font)
        leftButton.setTitleColor(.middleGray, for: [])
        
        rightButton.setFont(Text.style11.font)
        rightButton.setTitleColor(.darkBlue, for: [])
    }
    
    @IBAction func leftButtonPressed(_ sender: Any) {
        leftButtonAction?(self)
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
    
}
