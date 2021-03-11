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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var action: ((SaveButtonCollectionViewCell) -> Void)?
    var isSaving: Bool = false {
        didSet {
            if isSaving {
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                
                saveButton.isHidden = true
            } else {
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
                
                saveButton.isHidden = false
            }
        }
    }
    
    static let identifier = "SaveButtonCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        saveButton.setup()
    }
    
    func configure(title: String) {
        saveButton.configureActionButtonUI(title: title, bgColor: .barneyPurple)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if let action = action {
            action(self)
        }
    }
}
