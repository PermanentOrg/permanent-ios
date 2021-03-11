//
//  SaveButtonCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.03.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class SaveButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var saveButton: RoundedButton!
    
    static let identifier = "SaveButtonCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        saveButton.setup()
        // Initialization code
    }
    
    func configure(title: String) {
        saveButton.configureActionButtonUI(title: title, bgColor: .barneyPurple)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
