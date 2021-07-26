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
    
    weak var delegate: FABActionSheetDelegate?
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        sheetView.layer.masksToBounds = false
        sheetView.layer.shadowRadius = 4
        sheetView.layer.shadowColor = UIColor.black.withAlphaComponent(0.26).cgColor
        sheetView.layer.shadowOpacity = 1
        sheetView.layer.shadowOffset = CGSize(width: 0, height: -4)
        
        newFolderButton.bgColor = .galleryGray
        newFolderButton.setTitleColor(.darkBlue, for: [])
        
        uploadButton.bgColor = .primary
        uploadButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        newFolderButton.layer.cornerRadius = Constants.Design.actionButtonRadius
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .clear
        
        sheetView.backgroundColor = .backgroundPrimary
        sheetView.clipsToBounds = true
        sheetView.layer.cornerRadius = 8
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
        uploadButton.setTitle(.upload, for: [])
        uploadButton.addTarget(self, action: #selector(uploadAction), for: .touchUpInside)
        
        newFolderButton.setTitle(.newFolder, for: [])
        newFolderButton.addTarget(self, action: #selector(newFolderAction), for: .touchUpInside)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    }
    
    // MARK: - Actions
    
    @objc
    fileprivate func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    fileprivate func uploadAction() {
        dismiss(animated: true) {
            self.delegate?.didTapUpload()
        }
    }
    
    @objc
    fileprivate func newFolderAction() {
        dismiss(animated: true) {
            self.delegate?.didTapNewFolder()
        }
    }
}

protocol FABActionSheetDelegate: AnyObject {
    func didTapUpload()
    func didTapNewFolder()
}
