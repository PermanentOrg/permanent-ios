//
//  FileDetailsBottomCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsBottomCollectionViewCell: UICollectionViewCell {
    var viewModel: FilePreviewViewModel?
    var cellType: FileDetailsViewController.CellType?

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

    func configure(title: String, details: String, isDetailsFieldEditable: Bool = false, cellType:FileDetailsViewController.CellType, withViewModel vm:FilePreviewViewModel?) {
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font

        detailsTextField.text = details
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        detailsTextField.isUserInteractionEnabled = isDetailsFieldEditable
        if isDetailsFieldEditable {
            detailsTextField.backgroundColor = .darkGray
        }
        
        self.viewModel = vm
        self.cellType = cellType
    }
}

extension FileDetailsBottomCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch cellType {
        case .name:
            if let file = viewModel?.file,
               let name = detailsTextField.text {
                viewModel?.update(file: file, name: name, description: nil, date: nil, location: nil, completion: { (success) in })
                viewModel?.name = name
            }
        case .description:
            if let file = viewModel?.file {
                viewModel?.update(file: file, name: nil, description:  detailsTextField.text, date: nil, location: nil, completion: { (success) in })
            }
        default: break
        }
        return true
    }
}
