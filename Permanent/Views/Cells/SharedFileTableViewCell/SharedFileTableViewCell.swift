//
//  SharedFileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/12/2020.
//

import UIKit
import SDWebImage

class SharedFileTableViewCell: UITableViewCell {
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileDateLabel: UILabel!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var rightButtonImageView: UIImageView!
    @IBOutlet var fileImageView: UIImageView!
    @IBOutlet var dateStackView: UIStackView!
    @IBOutlet var sharesImageView: UIImageView!
    @IBOutlet var archiveImageView: UIImageView!
    @IBOutlet var progressView: UIProgressView!
    
    var rightButtonTapAction: CellButtonTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initUI()
    }
    
    private func initUI() {
        fileNameLabel.font = Text.style11.font
        fileNameLabel.textColor = .textPrimary
        fileDateLabel.font = Text.style12.font
        fileDateLabel.textColor = .textPrimary
        fileImageView.clipsToBounds = true
        
        sharesImageView.image = UIImage.group.templated
        sharesImageView.tintColor = .iconTintPrimary
        
        rightButtonImageView.tintColor = .iconTintPrimary
        progressView.progressTintColor = .primary
        archiveImageView.clipsToBounds = true
    }
    
    func updateCell(model: FileViewModel) {
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        sharesImageView.isHidden = false
        archiveImageView.sd_setImage(with: URL(string: model.archiveThumbnailURL))
        
        if model.type.isFolder {
            fileImageView.image = UIImage.folder.templated
            fileImageView.tintColor = .mainPurple
        } else {
            fileImageView.sd_setImage(with: URL(string: model.thumbnailURL))
        }
        
        handleUI(forStatus: model.fileStatus)
        
        moreButton.isEnabled = !model.type.isFolder
        rightButtonImageView.isHidden = model.type.isFolder
    }
    
    fileprivate func handleUI(forStatus status: FileStatus) {
        switch status {
        case .synced:
            progressView.isHidden = true
            rightButtonImageView.image = UIImage.more.templated
        break
            
        case .waiting:
            progressView.isHidden = true
            //statusLabel.isHidden = false
            //updateUploadOrDownloadUI()
            
        case .downloading:
            progressView.isHidden = false
            progressView.setProgress(0, animated: false)
        
            rightButtonImageView.image = UIImage.close.templated
        
        default:
            break
        }
    }
    
    fileprivate func setFileImage(forModel model: FileViewModel) {
        if model.type.isFolder {
            fileImageView.image = UIImage.folder.templated
            fileImageView.tintColor = .mainPurple
        } else {
            switch model.fileStatus {
            case .synced:
                if let imageURL = model.thumbnailURL {
                    // We display the placeholder until the images loads from the network.
                    fileImageView.image = .placeholder
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
    
    func updateProgress(withValue value: Float) {
        progressView.setProgress(value, animated: true)
    }

    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
}
