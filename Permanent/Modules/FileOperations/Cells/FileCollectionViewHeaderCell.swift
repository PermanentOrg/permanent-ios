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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftButton.setFont(TextFontStyle.style34.font)
        leftButton.setTitleColor(.lightGray, for: [])
        
        clearButton.setTitle("Clear".localized(), for: .normal)
        clearButton.setFont(TextFontStyle.style34.font)
        clearButton.setTitleColor(.paleRed, for: [])
        clearButton.isHidden = true
        
        rightButton.setFont(TextFontStyle.style34.font)
        rightButton.setTitleColor(.darkBlue, for: [])
        
        rightButton.semanticContentAttribute = .forceRightToLeft
        rightButton.imageView?.contentMode = .scaleAspectFit
    }
    
    func configure(with viewModel: FilesViewModel?, isPickingProfilePicture: Bool = false) {
         guard let viewModel = viewModel else {
             rightButtonTitle = nil
             rightButton.setImage(nil, for: .normal)
             clearButton.isHidden = true
             return
         }
         // Update right button title
         rightButtonTitle = viewModel.isSelecting ? "Select All" : nil
         
         // Update right button image
         if viewModel.isSelecting {
             let imageName: String
             switch viewModel.checkboxState {
             case .none:
                 imageName = "checkBoxEmpty"
             case .partial:
                 imageName = "checkboxPartial"
             case .selected:
                 imageName = "checkBoxCheckedFill"
             }
             let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
             rightButton.setImage(image, for: .normal)
             rightButton.tintColor = .darkBlue
         } else {
             rightButton.setImage(nil, for: .normal)
         }
         
         // Update clear button visibility
         clearButton.isHidden = !viewModel.isSelecting
        
        if isPickingProfilePicture {
            rightButton.isHidden = true
            clearButton.isHidden = true
        }
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
