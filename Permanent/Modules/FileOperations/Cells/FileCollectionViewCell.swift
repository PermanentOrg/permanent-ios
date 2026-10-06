//
//  FileCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 07.10.2021.
//

import UIKit
import SDWebImage

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
    @IBOutlet weak var sharingInfoStackView: UIStackView!
    
    var isGridCell: Bool = false
    var isSearchCell: Bool = false
    var fileAction: FileAction = .none
    var sharedFile: Bool = false
    var isSelecting: Bool = false
    var isFileSelected: Bool = false
    
    var fileInfoId: String?
    /// Whether this row's file is on the drag under way. iOS fades the row at a lifted file's place in the list,
    /// even after a hover has put another file there.
    var holdsDraggedFile: () -> Bool = { true }

    var rightButtonTapAction: ((FileCollectionViewCell) -> Void)?
    /// The loading rows' skeleton square under the picture, until the picture lands; still if its download fails.
    let thumbnailSkeleton = SkeletonSquareView()
    /// The picture this row waits for, so a late answer for the file the row showed before is ignored.
    private var awaitedThumbnail: URL?
    static let thumbnailFade: TimeInterval = 0.25
    private let moreButtonBadgeView = UIView()
    private let moreButtonBadgeLabel = UILabel()
    private var moreButtonBadgeWidthConstraint: NSLayoutConstraint?
    private var restingPanelColor: UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        restingPanelColor = overlayView.superview?.backgroundColor
        
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

        fileImageView.sd_cancelCurrentImageLoad()
        awaitedThumbnail = nil
        showThumbnailSkeleton(false)
        fileImageView.image = nil
        progressView.setProgress(.zero, animated: false)
        activityIndicator.stopAnimating()
        
        for subview in sharingInfoStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        syncSharingInfoVisibility()

        setMoreButtonBadgeCount(0)
        showDropTarget(false)
    }
    
    /// A folder under a drag that can take the files turns grey, as in the Files app. iOS fades the dragged rows itself.
    func showDropTarget(_ isTarget: Bool) {
        // The row's white panel covers the cell's own background, so the panel is what turns grey.
        overlayView.superview?.backgroundColor = isTarget ? .galleryGray : restingPanelColor
    }

    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        super.dragStateDidChange(dragState)
        // iOS has faded the row by now; a row that holds another file keeps its full colour.
        if dragState == .dragging, !holdsDraggedFile() { alpha = 1 }
    }

    private func initUI() {
        activityIndicator.stopAnimating()
        setUpThumbnailSkeleton()

        fileNameLabel.font = TextFontStyle.style35.font
        fileNameLabel.textColor = .black
        let fontLineHeight = TextFontStyle.style35.font.lineHeight
        let heightConstraint = fileNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: ceil(fontLineHeight))
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        fileDateLabel.font = TextFontStyle.style12.font
        fileDateLabel.textColor = .lightGray
        fileImageView.clipsToBounds = true
        
        sharesImageView.image = UIImage.group.templated
        sharesImageView.tintColor = .iconTintPrimary
        
        statusLabel.font = TextFontStyle.style12.font
        statusLabel.textColor = .middleGray
        statusLabel.text = .waiting
        
        progressView.progressTintColor = .primary
        rightButtonImageView.tintColor = .iconTintPrimary
        
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        moreButtonBadgeView.translatesAutoresizingMaskIntoConstraints = false
        moreButtonBadgeView.backgroundColor = UIColor(.error500)
        moreButtonBadgeView.layer.cornerRadius = 8
        moreButtonBadgeView.layer.masksToBounds = true
        moreButtonBadgeView.isHidden = true
        
        moreButtonBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        moreButtonBadgeLabel.textColor = .white
        moreButtonBadgeLabel.font = TextFontStyle.style52.font
        moreButtonBadgeLabel.textAlignment = .center
        moreButtonBadgeView.addSubview(moreButtonBadgeLabel)
        
        contentView.addSubview(moreButtonBadgeView)
        
        //moreButtonBadgeWidthConstraint = moreButtonBadgeView.widthAnchor.constraint(equalToConstant: 10)
        
        NSLayoutConstraint.activate([
            //moreButtonBadgeWidthConstraint!,
            moreButtonBadgeView.widthAnchor.constraint(equalToConstant: 20),
            moreButtonBadgeView.heightAnchor.constraint(equalToConstant: 16),
            moreButtonBadgeView.centerYAnchor.constraint(equalTo: moreButton.centerYAnchor),
            moreButtonBadgeView.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: 6),
            moreButtonBadgeLabel.centerYAnchor.constraint(equalTo: moreButtonBadgeView.centerYAnchor),
            moreButtonBadgeLabel.centerXAnchor.constraint(equalTo: moreButtonBadgeView.centerXAnchor)
        ])
    }
    
    /// The square sits under the picture, in the picture's own frame.
    private func setUpThumbnailSkeleton() {
        // A picture from the network or the disk fades in over the square, which goes once the picture covers it.
        let fade = SDWebImageTransition.fade(duration: Self.thumbnailFade)
        fade.completion = { [weak self] _ in self?.showThumbnailSkeleton(false) }
        fileImageView.sd_imageTransition = fade
        guard let slot = fileImageView.superview else { return }
        thumbnailSkeleton.translatesAutoresizingMaskIntoConstraints = false
        thumbnailSkeleton.isHidden = true
        slot.insertSubview(thumbnailSkeleton, belowSubview: fileImageView)
        NSLayoutConstraint.activate([
            thumbnailSkeleton.leadingAnchor.constraint(equalTo: fileImageView.leadingAnchor),
            thumbnailSkeleton.trailingAnchor.constraint(equalTo: fileImageView.trailingAnchor),
            thumbnailSkeleton.topAnchor.constraint(equalTo: fileImageView.topAnchor),
            thumbnailSkeleton.bottomAnchor.constraint(equalTo: fileImageView.bottomAnchor)
        ])
        showThumbnailSkeleton(false)
    }

    private func showThumbnailSkeleton(_ shows: Bool, sweeping: Bool = true) {
        thumbnailSkeleton.isHidden = !shows
        thumbnailSkeleton.shimmer.isOn = shows && sweeping
        thumbnailSkeleton.shimmer.update()
    }

    private func loadThumbnail(_ url: URL) {
        awaitedThumbnail = url
        // `.retryFailed`, because one transient CDN failure otherwise blacklists the URL session-wide and
        // leaves this thumbnail blank until restart.
        fileImageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed]) { [weak self] image, error, cacheType, loaded in
            guard let self, loaded == self.awaitedThumbnail, !Self.isCancelled(error) else { return }
            if image == nil {
                self.showThumbnailSkeleton(true, sweeping: false)
            } else if cacheType == .memory {
                // Already in memory, so it shows at once with no fade; any other picture's fade takes the square away.
                self.showThumbnailSkeleton(false)
            }
        }
    }

    private static func isCancelled(_ error: Error?) -> Bool {
        (error as? SDWebImageError)?.code == .cancelled || (error as? URLError)?.code == .cancelled
    }

    func updateCell(model: FileModel, fileAction: FileAction, isGridCell: Bool, isSearchCell: Bool, sharedFile: Bool = false, isSelecting: Bool = false, isFileSelected: Bool = false) {
        self.isGridCell = isGridCell
        self.isSearchCell = isSearchCell
        self.fileAction = fileAction
        self.sharedFile = sharedFile
        self.isSelecting = isSelecting
        self.isFileSelected = isFileSelected
        
        rightButtonImageView.isHidden = false
        
        fileNameLabel.text = model.name
        fileDateLabel.text = model.date
        
        sharesImageView.isHidden = model.minArchiveVOS.isEmpty || sharedFile
        
        setFileImage(forModel: model)
        handleUI(forStatus: model.fileStatus)
        toggleInteraction(forModel: model, action: fileAction)
        
        if let fileId = model.fileInfoId,
           let progress = UploadManager.shared.operation(forFileId: fileId)?.progress {
            fileInfoId = model.fileInfoId
            updateProgress(withValue: Float(progress))
        }
        
        if sharedFile {
            updateSharingInfo(withModel: model)
        }
        syncSharingInfoVisibility()

        if isSelecting {
            if isFileSelected {
                rightButtonImageView.image = UIImage(named: "fullCheckbox")?.templated
                fileNameLabel.font = TextFontStyle.style35.font
                fileNameLabel.textColor = .darkBlue
                rightButtonImageView.tintColor = .darkBlue
            } else {
                rightButtonImageView.image = UIImage(named: "emptyCheckbox")?.templated
                fileNameLabel.font = TextFontStyle.style34.font
                fileNameLabel.textColor = .lightGray
                rightButtonImageView.tintColor = .lightGray
            }
        } else {
            if fileAction == .none {
                rightButtonImageView.image = UIImage.more.templated
                fileNameLabel.font = TextFontStyle.style35.font
                fileNameLabel.textColor = .black
                rightButtonImageView.tintColor = .darkBlue
            } else {
                rightButtonImageView.image = nil
                if isFileSelected {
                    fileNameLabel.font = TextFontStyle.style34.font
                    fileNameLabel.textColor = .lightGray
                    rightButtonImageView.tintColor = .lightGray
                } else {
                    fileNameLabel.font = TextFontStyle.style35.font
                    fileNameLabel.textColor = .darkBlue
                    rightButtonImageView.tintColor = .darkBlue
                }
                
            }
        }
    }
    
    fileprivate func toggleInteraction(forModel model: FileModel, action: FileAction) {
        var hasRightButton = true
        if model.fileStatus == .synced {
            let fileURL = URL(string: model.thumbnailURL)
            hasRightButton = hasRightButton && (fileURL != nil || model.canBeAccessed) && !isSearchCell
        }
        
        if model.type.isFolder {
            overlayView.isHidden = true
            isUserInteractionEnabled = true
            if !sharedFile {
                moreButton.isEnabled = action == .none
                rightButtonImageView.tintColor = action == .none ? .primary : UIColor.primary.withAlphaComponent(0.5)
            }
            
            let hasRightButtonPermission = model.permissions.contains(.create) ||
                model.permissions.contains(.delete) ||
                model.permissions.contains(.move) ||
                model.permissions.contains(.publish) ||
                model.permissions.contains(.share) ||
                model.permissions.contains(.edit) ||
                model.permissions.contains(.read)
            hasRightButton = hasRightButton && hasRightButtonPermission
        } else {
            overlayView.isHidden = action == .none
            isUserInteractionEnabled = action == .none

            if !sharedFile {
                moreButton.isEnabled = action == .none
                rightButtonImageView.tintColor = .primary
            }
        }
        
        if !sharedFile {
            moreButton.isHidden = !hasRightButton
            rightButtonImageView.isHidden = !hasRightButton
        }
    }
    
    fileprivate func setFileImage(forModel model: FileModel) {
        // A download still on its way for the file shown before would land over this one's picture or mark.
        fileImageView.sd_cancelCurrentImageLoad()
        awaitedThumbnail = nil
        showThumbnailSkeleton(false)
        if model.type.isFolder {
            fileImageView.contentMode = .scaleAspectFit
            fileImageView.image = UIImage.folder.templated
            fileImageView.tintColor = .mainPurple
        } else {
            switch model.fileStatus {
            case .synced:
                fileImageView.contentMode = .scaleAspectFill
                // A row fresh from its nib still holds the nib's folder image, which would cover the square.
                fileImageView.image = nil
                // The skeleton square sweeps while the picture is on its way, and while the server has not made it yet.
                showThumbnailSkeleton(true)
                if let fileURL = URL(string: model.thumbnailURL) {
                    loadThumbnail(fileURL)
                }

            case .downloading:
                fileImageView.contentMode = .scaleAspectFit
                fileImageView.image = .download
                
            case .uploading, .waiting, .failed:
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
            statusLabel.text = .waiting
            updateUploadOrDownloadUI()
            
        case .failed:
            progressView.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "Failed to upload. Retrying...".localized()
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
    
    /// A visible-but-empty arranged subview still costs the stack its spacing, and this one is only
    /// populated for shared rows. Derived from the subviews, so it reappears by itself with content.
    private func syncSharingInfoVisibility() {
        sharingInfoStackView.isHidden = sharingInfoStackView.arrangedSubviews.isEmpty
    }

    func updateSharingInfo(withModel model: FileModel) {
        if model.sharedByArchive != nil {
            guard let archive = model.sharedByArchive else { return }
            
            let extraLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
            extraLabel.font = TextFontStyle.style8.font
            extraLabel.textColor = .middleGray
            extraLabel.contentMode = .center
            extraLabel.text = "The \(archive.name) Archive"
            sharingInfoStackView.addArrangedSubview(extraLabel)
        } else {
            let maxArchivesCount = 3
            model.minArchiveVOS[0 ..< min(model.minArchiveVOS.count, maxArchivesCount)].forEach { archiveVO in
                guard let thumbnailUrl = URL(string: archiveVO.thumbnail) else { return }
                
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                imageView.constraintToSquare(20)
                imageView.sd_setImage(with: thumbnailUrl, placeholderImage: nil, options: [.retryFailed])
                sharingInfoStackView.addArrangedSubview(imageView)
            }
            
            if model.minArchiveVOS.count > maxArchivesCount {
                let extraLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
                extraLabel.font = TextFontStyle.style8.font
                extraLabel.textColor = .middleGray
                extraLabel.contentMode = .center
                extraLabel.text = " +\(model.minArchiveVOS.count - maxArchivesCount)"
                sharingInfoStackView.addArrangedSubview(extraLabel)
            }
        }
    }
    
    @IBAction
    func moreButtonAction(_ sender: AnyObject) {
        rightButtonTapAction?(self)
    }

    func setMoreButtonBadgeCount(_ count: Int) {
        guard count > 0 else {
            moreButtonBadgeView.isHidden = true
            moreButtonBadgeLabel.text = nil
            moreButtonBadgeWidthConstraint?.constant = 24
            return
        }
        
        let badgeText = count > 9 ? "9+" : "\(count)"
        moreButtonBadgeLabel.text = badgeText
        moreButtonBadgeView.isHidden = false
    }
}
