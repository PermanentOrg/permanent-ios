//
//  FileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/10/2020.
//

import UIKit

class FileTableViewCell: UITableViewCell {
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileDateLabel: UILabel!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var fileImageView: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var dateStackView: UIStackView!
    @IBOutlet var overlayView: UIView!
    
    var rightButtonTapAction: CellButtonTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
    }
    
    private func initUI() {
        fileNameLabel.font = Text.style11.font
        fileNameLabel.textColor = .middleGray
        fileDateLabel.font = Text.style12.font
        fileDateLabel.textColor = .middleGray
        fileImageView.clipsToBounds = true
        
        statusLabel.font = Text.style12.font
        statusLabel.textColor = .middleGray
        statusLabel.text = .waiting
        
        progressView.progressTintColor = .primary
        moreButton.tintColor = .middleGray
        
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    func updateCell(model: FileViewModel, fileAction: FileAction) {
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        
        setFileImage(forModel: model)
        handleUI(forStatus: model.fileStatus)
        toggleInteraction(forModel: model, action: fileAction)
    }
    
    fileprivate func toggleInteraction(forModel model: FileViewModel, action: FileAction) {
        if model.type.isFolder {
            overlayView.isHidden = true
            self.isUserInteractionEnabled = true
        } else {
            overlayView.isHidden = action == .none
            self.isUserInteractionEnabled = action == .none
        }
    }
    
    fileprivate func setFileImage(forModel model: FileViewModel) {
        if model.type.isFolder {
            fileImageView.image = .folder
        } else {
            switch model.fileStatus {
            case .synced:
                if let imageURL = model.thumbnailURL {
                    fileImageView.load(urlString: imageURL)
                } else {
                    // File is in the synced list, but it does not have a thumbnail yet.
                    fileImageView.image = .placeholder
                }
                
            case .downloading:
                fileImageView.image = .download
                
            case .uploading, .waiting:
                fileImageView.image = .cloud // TODO: waiting can be used on download, too.
            }
        }
    }
    
    fileprivate func handleUI(forStatus status: FileStatus) {
        switch status {
        case .synced:
            updateSyncedUI()
            
        case .waiting, .downloading:
            progressView.isHidden = true
            statusLabel.isHidden = false
            updateUploadingUI()
            
        case .uploading:
            statusLabel.isHidden = true
            progressView.isHidden = false
            progressView.setProgress(0, animated: false)
            
            updateUploadingUI()
        }
    }
    
    fileprivate func updateUploadingUI() {
        dateStackView.isHidden = true
        moreButton.setImage(UIImage.close.templated, for: [])
    }
    
    fileprivate func updateSyncedUI() {
        progressView.isHidden = true
        statusLabel.isHidden = true
        dateStackView.isHidden = false
        moreButton.setImage(UIImage.more.templated, for: [])
    }
    
    func updateProgress(withValue value: Float) {
        progressView.setProgress(value, animated: true)
    }
    
    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
}
