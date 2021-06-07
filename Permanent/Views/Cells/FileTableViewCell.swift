//
//  FileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/10/2020.
//

import UIKit
import SDWebImage

class FileTableViewCell: UITableViewCell {
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileDateLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var rightButtonImageView: UIImageView!
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var sharesImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var rightButtonTapAction: CellButtonTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        fileImageView.image = nil
        activityIndicator.stopAnimating()
    }
    
    private func initUI() {
        activityIndicator.stopAnimating()
        
        fileNameLabel.font = Text.style11.font
        fileNameLabel.textColor = .textPrimary
        fileDateLabel.font = Text.style12.font
        fileDateLabel.textColor = .textPrimary
        fileImageView.clipsToBounds = true
        
        sharesImageView.image = UIImage.group.templated
        sharesImageView.tintColor = .iconTintPrimary
        
        statusLabel.font = Text.style12.font
        statusLabel.textColor = .middleGray
        statusLabel.text = .waiting
        
        progressView.progressTintColor = .primary
        rightButtonImageView.tintColor = .iconTintPrimary
        
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    func updateCell(model: FileViewModel, fileAction: FileAction) {
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        sharesImageView.isHidden = model.minArchiveVOS.isEmpty
        
        setFileImage(forModel: model)
        handleUI(forStatus: model.fileStatus)
        toggleInteraction(forModel: model, action: fileAction)
        
        let fileURL = URL(string: model.thumbnailURL)
        moreButton.isHidden = fileURL == nil
        rightButtonImageView.isHidden = fileURL == nil
    }
    
    fileprivate func toggleInteraction(forModel model: FileViewModel, action: FileAction) {
        if model.type.isFolder {
            overlayView.isHidden = true
            self.isUserInteractionEnabled = true
            moreButton.isEnabled = action == .none
            rightButtonImageView.tintColor = action == .none ? .iconTintPrimary : UIColor.iconTintPrimary.withAlphaComponent(0.5)
        } else {
            overlayView.isHidden = action == .none
            self.isUserInteractionEnabled = action == .none
            moreButton.isEnabled = action == .none
            rightButtonImageView.tintColor = .iconTintPrimary
        }
    }
    
    fileprivate func setFileImage(forModel model: FileViewModel) {
        if model.type.isFolder {
            fileImageView.contentMode = .scaleAspectFit
            fileImageView.image = UIImage.folder.templated
            fileImageView.tintColor = .mainPurple
        } else {
            switch model.fileStatus {
            case .synced:
                fileImageView.contentMode = .scaleAspectFill
                if let fileURL = URL(string: model.thumbnailURL) {
                    fileImageView.sd_setImage(with: fileURL, placeholderImage: .placeholder)
                } else {
                    activityIndicator.startAnimating()
                }
                
            case .downloading:
                fileImageView.contentMode = .scaleAspectFit
                fileImageView.image = .download
                
            case .uploading, .waiting:
                fileImageView.contentMode = .scaleAspectFit
                fileImageView.image = .cloud // TODO: waiting can be used on download, too.
            }
        }
    }
    
    fileprivate func handleUI(forStatus status: FileStatus) {
        switch status {
        case .synced:
            updateSyncedUI()
            
        case .waiting:
            progressView.isHidden = true
            statusLabel.isHidden = false
            updateUploadOrDownloadUI()
            
        case .uploading, .downloading:
            statusLabel.isHidden = true
            progressView.isHidden = false
            progressView.setProgress(0, animated: false)
            
            updateUploadOrDownloadUI()
        }
    }
    
    fileprivate func updateUploadOrDownloadUI() {
        dateStackView.isHidden = true
        rightButtonImageView.image = UIImage.close.templated
    }
    
    fileprivate func updateSyncedUI() {
        progressView.isHidden = true
        statusLabel.isHidden = true
        dateStackView.isHidden = false
        rightButtonImageView.image = UIImage.more.templated
    }
    
    func updateProgress(withValue value: Float) {
        progressView.setProgress(value, animated: true)
    }
    
    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
}
