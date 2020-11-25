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
    
    weak var delegate: FileActionSheetDelegate?
    
    private var file: FileViewModel!
    private var indexPath: IndexPath!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        styleActionButton(downloadButton, color: .primary, text: .download)
        styleActionButton(copyButton, color: .primary, text: .copy)
        styleActionButton(moveButton, color: .primary, text: .move)
        styleActionButton(deleteButton, color: .destructive, text: .delete)
        //styleActionButton(publishButton, color: .primary, text: .publish)
        //styleActionButton(editButton, color: .primary, text: .edit)
        //styleActionButton(shareButton, color: .primary, text: .share)
    }
    
    convenience init(
        frame: CGRect,
        title: String?,
        file: FileViewModel,
        indexPath: IndexPath
    ) {
        self.init(frame: frame)
        self.file = file
        self.indexPath = indexPath
                
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
        shareButton.isHidden = true
    }
    
    fileprivate func styleActionButton(_ button: RoundedButton, color: UIColor, text: String) {
        button.bgColor = color
        button.layer.cornerRadius = Constants.Design.actionButtonRadius
        button.setTitle(text, for: [])
    }
    
    // MARK: - Actions

    @objc
    func dismiss() {
        removeFromSuperview()
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
}
