//
//  FileDetailsBottomCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsBottomCollectionViewCell: UICollectionViewCell {

    static let identifier = "FileDetailsBottomCollectionViewCell"
    
    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsTextField: UITextField!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        detailsTextField.delegate = self
    }

    func configure(title: String, details: String, isDetailsFieldEditable: Bool = false, isLocationField: Bool = false) {
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font

        detailsTextField.text = details
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        detailsTextField.isUserInteractionEnabled = isDetailsFieldEditable
        if isDetailsFieldEditable || isLocationField {
            detailsTextField.backgroundColor = .darkGray
        }
        if isLocationField { detailsTextField.isUserInteractionEnabled = false}
    }
}

extension FileDetailsBottomCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
