//
//  FileActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import UIKit

protocol FileActionSheetDelegate: class {
    func downloadAction(file: FileViewModel)
    func deleteAction(file: FileViewModel, atIndexPath indexPath: IndexPath)
    func relocateAction(file: FileViewModel, action: FileAction)
    func share(file: FileViewModel)
}

class FileActionSheet: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var sheetView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var downloadButton: RoundedButton!
    @IBOutlet var copyButton: RoundedButton!
    @IBOutlet var moveButton: RoundedButton!
    @IBOutlet var publishButton: RoundedButton!
    @IBOutlet var deleteButton: RoundedButton!
    @IBOutlet var editButton: RoundedButton!
    @IBOutlet var shareButton: RoundedButton!
    @IBOutlet var safeAreaView: UIView!
    
    weak var delegate: FileActionSheetDelegate?
    
    private var onDismiss: ButtonAction!
    private var file: FileViewModel!
    private var indexPath: IndexPath!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        //styleActionButton(publishButton, color: .primary, text: .publish)
        //styleActionButton(editButton, color: .primary, text: .edit)
    }
    
    convenience init(
        frame: CGRect,
        title: String?,
        file: FileViewModel,
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
        
        // Hide these buttons temporarily
        publishButton.isHidden = true
        editButton.isHidden = true
        
        safeAreaView.backgroundColor = .backgroundPrimary
        
        configureButtons()
    }
    
    fileprivate func configureButtons() {
        styleActionButton(copyButton, color: .primary, text: .copy)
        styleActionButton(moveButton, color: .primary, text: .move)
        styleActionButton(deleteButton, color: .destructive, text: .delete)
        styleActionButton(shareButton, color: .primary, text: .share)
        
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
    
    @IBAction
    func deleteAction(_ sender: UIButton) {
        delegate?.deleteAction(file: self.file, atIndexPath: self.indexPath)
        
        dismiss()
    }
    
    @IBAction func copyAction(_ sender: UIButton) {
        delegate?.relocateAction(file: self.file, action: .copy)
        
        dismiss()
    }
    
    @IBAction
    func moveAction(_ sender: UIButton) {
        delegate?.relocateAction(file: self.file, action: .move)
        
        dismiss()
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        delegate?.share(file: self.file)
        
        dismiss()
    }
}
