//
//  SharedFileTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/12/2020.
//

import UIKit

class SharedFileTableViewCell: UITableViewCell {
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileDateLabel: UILabel!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var fileImageView: UIImageView!
    @IBOutlet var dateStackView: UIStackView!
    @IBOutlet var sharesImageView: UIImageView!
    @IBOutlet var archiveImageView: UIImageView!
    
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
        
        moreButton.tintColor = .iconTintPrimary
        
        archiveImageView.clipsToBounds = true
    }
    
    func updateCell(model: SharedFileData) {
        fileNameLabel.text = model.fileName
        fileDateLabel.text = model.date
        sharesImageView.isHidden = false
        fileImageView.load(urlString: model.thumbnailURL)
        archiveImageView.load(urlString: model.archiveThumbnailURL)
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

    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }
}
