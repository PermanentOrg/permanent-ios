//
//  FileDetailsBottomCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class FileDetailsBottomCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsTextField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    static let identifier = "FileDetailsBottomCollectionViewCell"
    

    func configure(title: String,details: String) {
        
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font
        detailsTextField.text = details
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        
    }
        
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
}
