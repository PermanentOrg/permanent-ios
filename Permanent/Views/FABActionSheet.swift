//
//  FABActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 20/10/2020.
//

import UIKit

class FABActionSheet: UIViewController {
    @IBOutlet var sheetView: UIView!
    @IBOutlet var uploadButton: RoundedButton!
    @IBOutlet var newFolderButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        sheetView.layer.masksToBounds = false
        sheetView.layer.shadowRadius = 4
        sheetView.layer.shadowColor = UIColor.black.withAlphaComponent(0.26).cgColor
        sheetView.layer.shadowOpacity = 1
        sheetView.layer.shadowOffset = CGSize(width: 0, height: -4)
        
        newFolderButton.backgroundColor = .galleryGray
        newFolderButton.setTitleColor(.darkBlue, for: [])
        
        uploadButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        newFolderButton.layer.cornerRadius = Constants.Design.actionButtonRadius
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .clear
        
        sheetView.backgroundColor = .backgroundPrimary
        sheetView.clipsToBounds = true
        sheetView.layer.cornerRadius = 8
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
        uploadButton.setTitle(Translations.upload, for: [])
        newFolderButton.setTitle(Translations.newFolder, for: [])
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sheetTapAction)))
    }
    
    // MARK: - Actions
    
    @objc
    fileprivate func sheetTapAction() {
        dismiss(animated: true, completion: nil)
    }
}
