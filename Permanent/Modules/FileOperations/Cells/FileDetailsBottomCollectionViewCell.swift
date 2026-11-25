//
//  FileDetailsBottomCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.03.2021.
//

import UIKit

class FileDetailsBottomCollectionViewCell: FileDetailsBaseCollectionViewCell {
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

    override func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        super.configure(withViewModel: viewModel, type: type)
        
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = TextFontStyle.style9.font

        detailsTextField.text = cellDetails()
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = TextFontStyle.style8.font
        
        detailsTextField.isUserInteractionEnabled = isEditable
        if isEditable {
            detailsTextField.backgroundColor = .darkGray
        }
    }
    
    func cellDetails() -> String {
        guard let recordVO = viewModel?.recordVO?.recordVO else { return "" }
        
        let details: String
        switch cellType {
        case .name:
            details = recordVO.displayName ?? ""

        case .description:
            details = recordVO.recordVODescription ?? ""

        case .tags:
            details = recordVO.tagVOS?.map({ ($0.name ?? "") }).joined(separator: ",") ?? ""

        case .size:
            details = Int64(recordVO.size ?? 0).readableFileSize

        case .fileType:
            details = URL(string: recordVO.type)?.pathExtension ?? ""

        case .originalFileName:
            details = URL(string: recordVO.uploadFileName)?.deletingPathExtension().absoluteString ?? ""

        case .originalFileType:
            details = URL(string: recordVO.uploadFileName?.uppercased())?.pathExtension ?? ""

        default:
            details = "-"
        }
        return details
    }
}

extension FileDetailsBottomCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
