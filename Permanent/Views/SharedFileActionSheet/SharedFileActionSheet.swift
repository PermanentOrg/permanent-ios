//
//  FileActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import UIKit

protocol SharedFileActionSheetDelegate: class {
    func downloadAction(file: SharedFileViewModel)
}

class SharedFileActionSheet: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var sheetView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var downloadButton: RoundedButton!
    @IBOutlet var safeAreaView: UIView!
    
    weak var delegate: SharedFileActionSheetDelegate?
    
    private var onDismiss: ButtonAction!
    private var file: SharedFileViewModel!
    private var indexPath: IndexPath!
    
    convenience init(
        frame: CGRect,
        title: String?,
        file: SharedFileViewModel,
        indexPath: IndexPath,
        onDismiss: @escaping ButtonAction
    ) {
        self.init(frame: frame)
        self.file = file
        self.indexPath = indexPath
        self.onDismiss = onDismiss
            
        initUI(title: title)
    }
    
    func initUI(title: String?) {
        loadNib()
        setupView(contentView)

        sheetView.layer.cornerRadius = 4
        titleLabel.text = title
        titleLabel.font = Text.style11.font
        titleLabel.textColor = .textPrimary
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    
        safeAreaView.backgroundColor = .backgroundPrimary
        
        configureButtons()
    }
    
    fileprivate func configureButtons() {
        if file.type.isFolder {
            downloadButton.isHidden = true
        } else {
            styleActionButton(downloadButton, color: .primary, text: .download)
        }
    }
    
    fileprivate func styleActionButton(_ button: RoundedButton, color: UIColor, text: String) {
        button.bgColor = color
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
        button.setTitle(text, for: [])
    }
    
    // MARK: - Actions

    @objc
    func dismiss() {
        onDismiss()
    }
    
    @IBAction
    func downloadAction(_ sender: UIButton) {
        delegate?.downloadAction(file: self.file)
        
        dismiss()
    }
}
