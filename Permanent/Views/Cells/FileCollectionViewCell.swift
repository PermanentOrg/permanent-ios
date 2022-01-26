//
//  FileCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 07.10.2021.
//

import UIKit

class FileCollectionViewCell: UICollectionViewCell {
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
    
    var isGridCell: Bool = false
    var isSearchCell: Bool = false
    
    var fileInfoId: String?
    
    var rightButtonTapAction: ((FileCollectionViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
        
        NotificationCenter.default.addObserver(forName: UploadOperation.uploadProgressNotification, object: nil, queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let fileInfoId = userInfo["fileInfoId"] as? String,
                  let progress = userInfo["progress"] as? Double,
                  fileInfoId == self?.fileInfoId else { return }
            
            self?.handleUI(forStatus: .uploading)
            self?.progressView.setProgress(Float(progress), animated: true)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        fileInfoId = nil
        rightButtonTapAction = nil

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
    
    func updateCell(model: FileViewModel, fileAction: FileAction, isGridCell: Bool, isSearchCell: Bool) {
        self.isGridCell = isGridCell
        self.isSearchCell = isSearchCell
        
        rightButtonImageView.isHidden = false
        
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        sharesImageView.isHidden = model.minArchiveVOS.isEmpty
        
        setFileImage(forModel: model)
        handleUI(forStatus: model.fileStatus)
        toggleInteraction(forModel: model, action: fileAction)
        
        if let fileId = model.fileInfoId,
           let progress = UploadManager.shared.operation(forFileId: fileId)?.progress {
            fileInfoId = model.fileInfoId
            updateProgress(withValue: Float(progress))
        }
    }
    
    fileprivate func toggleInteraction(forModel model: FileViewModel, action: FileAction) {
        var hasRightButton = true
        if model.fileStatus == .synced {
            let fileURL = URL(string: model.thumbnailURL)
            hasRightButton = hasRightButton && fileURL != nil && !isSearchCell
        }
        
        if model.type.isFolder {
            overlayView.isHidden = true
            isUserInteractionEnabled = true
            moreButton.isEnabled = action == .none
            rightButtonImageView.tintColor = action == .none ? .primary : UIColor.primary.withAlphaComponent(0.5)
            
            let hasRightButtonPermission = model.permissions.contains(.create) ||
                model.permissions.contains(.delete) ||
                model.permissions.contains(.move) ||
                model.permissions.contains(.publish) ||
                model.permissions.contains(.share)
            hasRightButton = hasRightButton && hasRightButtonPermission
        } else {
            overlayView.isHidden = action == .none
            isUserInteractionEnabled = action == .none
            moreButton.isEnabled = action == .none
            rightButtonImageView.tintColor = .primary
        }
        
        moreButton.isHidden = !hasRightButton
        rightButtonImageView.isHidden = !hasRightButton
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
        if isGridCell {
            progressView.isHidden = true
            statusLabel.isHidden = true
            dateStackView.isHidden = true
        } else {
            progressView.isHidden = true
            statusLabel.isHidden = true
            dateStackView.isHidden = false
        }
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
