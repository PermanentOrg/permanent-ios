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
        titleLabelField.font = Text.style9.font

        detailsTextField.text = cellDetails()
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        
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
            details = ByteCountFormatter.string(fromByteCount: Int64(recordVO.size ?? 0), countStyle: .file)
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch cellType {
        case .name:
            if (textField.text?.isEmpty ?? false) || textField.text == viewModel?.name {
                textField.text = viewModel?.name
                return
            } else if let file = viewModel?.file,
               let name = detailsTextField.text {
                let initialValue = viewModel?.name
                viewModel?.update(file: file, name: name, description: nil, date: nil, location: nil, completion: { (success) in
                    if !success {
                        textField.text = initialValue
                    }
                })
                viewModel?.name = name
            }
            
        case .description:
            if (textField.text?.isEmpty ?? false) || textField.text == viewModel?.recordVO?.recordVO?.recordVODescription {
                textField.text = viewModel?.recordVO?.recordVO?.recordVODescription
                return
            } else if let file = viewModel?.file {
                let initialValue = viewModel?.recordVO?.recordVO?.recordVODescription
                viewModel?.update(file: file, name: nil, description:  detailsTextField.text, date: nil, location: nil, completion: { (success) in
                    if !success {
                        textField.text = initialValue
                    }
                })
            }
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
