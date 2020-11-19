//
//  FileActionSheet.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import UIKit

protocol FileActionSheetDelegate: class {
    func downloadAction(file: FileViewModel)
    func deleteAction(file: FileViewModel)
    func copyAction(file: FileViewModel)
}

class FileActionSheet: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var sheetView: UIView!
    // @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var downloadButton: RoundedButton!
    @IBOutlet var copyButton: RoundedButton!
    @IBOutlet var moveButton: RoundedButton!
    @IBOutlet var publishButton: RoundedButton!
    @IBOutlet var deleteButton: RoundedButton!
    @IBOutlet var editButton: RoundedButton!
    @IBOutlet var shareButton: RoundedButton!
    
    weak var delegate: FileActionSheetDelegate?
    
    private var file: FileViewModel!
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        styleActionButton(downloadButton, color: .primary, text: .download)
        styleActionButton(copyButton, color: .primary, text: .copy)
        styleActionButton(moveButton, color: .primary, text: .move)
        styleActionButton(publishButton, color: .primary, text: .publish)
        styleActionButton(deleteButton, color: .destructive, text: .delete)
        styleActionButton(editButton, color: .primary, text: .edit)
        styleActionButton(shareButton, color: .primary, text: .share)
        
        
//        UIView.animate(withDuration: 0.5, delay: 0.2, options: UIView.AnimationOptions.curveEaseOut, animations: {
//            self.contentView.backgroundColor = UIColor.overlay
//        }, completion: nil)
        
        
    }
    
    convenience init(
        frame: CGRect,
        file: FileViewModel
    ) {
        self.init(frame: frame)
        self.file = file
        
        commonInit()
        
        // titleLabel.text = title
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(String(describing: FileActionSheet.self), owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.backgroundColor = .clear
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        initUI()
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }
    
    fileprivate func initUI() {
        
        sheetView.layer.cornerRadius = 4
        
        // titleLabel.font = Text.style3.font
        // titleLabel.textColor = .primary
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
        delegate?.deleteAction(file: self.file)
    }
    
    @IBAction func copyAction(_ sender: UIButton) {
        delegate?.copyAction(file: self.file)
        
        dismiss()
    }
}
