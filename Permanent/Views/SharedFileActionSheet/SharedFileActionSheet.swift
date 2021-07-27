//
//  FileActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import UIKit

protocol SharedFileActionSheetDelegate: AnyObject {
    func downloadAction(file: FileViewModel)
}

class SharedFileActionSheet: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var sheetView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var downloadButton: RoundedButton!
    @IBOutlet var safeAreaView: UIView!
    
    weak var delegate: SharedFileActionSheetDelegate?
    
    private var onDismiss: ButtonAction!
    private var file: FileViewModel!
    private var indexPath: IndexPath!
    
    var hasDownloadButton: Bool!
    
    convenience init(
        frame: CGRect,
        title: String?,
        file: FileViewModel,
        indexPath: IndexPath,
        hasDownloadButton: Bool,
        onDismiss: @escaping ButtonAction
    ) {
        self.init(frame: frame)
        self.file = file
        self.indexPath = indexPath
        self.onDismiss = onDismiss
        self.hasDownloadButton = hasDownloadButton
            
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
        if file.type.isFolder || hasDownloadButton == false {
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
