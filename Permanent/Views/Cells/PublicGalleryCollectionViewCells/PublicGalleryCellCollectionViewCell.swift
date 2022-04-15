//
//  PublicGalleryCellCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.04.2022.
//

import UIKit

class PublicGalleryCellCollectionViewCell: UICollectionViewCell {
    static let identifier = "PublicGalleryCellCollectionViewCell"
    @IBOutlet weak var archiveImage: UIImageView!
    @IBOutlet weak var archiveTitleLabel: UILabel!
    @IBOutlet weak var archiveUserRole: UILabel!
    @IBOutlet weak var linkIconButton: UIButton!
    @IBOutlet weak var rightSideBackgroundView: UIView!
    
    var buttonAction: ButtonAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(archive: ArchiveVOData?, section: PublicGalleryCellType) {
        guard let thumbnail = archive?.thumbURL1000,
            let name = archive?.fullName else { return }
        let role = archive?.accessRole ?? ""
        
        archiveImage.load(urlString: thumbnail)
        archiveTitleLabel.text = name
        archiveUserRole.text = AccessRole.roleForValue(role).groupName
        
        switch section {
        case .onlineArchives:
            initUIforLocalArchive()
        case .popularPublicArchives:
            initUIforPublicArchive()
        }
    }
    
    private func initUIforLocalArchive() {
        rightSideBackgroundView.backgroundColor = .primary
        
        archiveTitleLabel.textColor = .white
        archiveTitleLabel.font = Text.style9.font
        archiveUserRole.textColor = .white
        archiveUserRole.font = Text.style12.font
        linkIconButton.tintColor = .white
    }
    
    private func initUIforPublicArchive() {
        rightSideBackgroundView.backgroundColor = .galleryGray
        
        archiveTitleLabel.textColor = .primary
        archiveTitleLabel.font = Text.style9.font
        archiveUserRole.isHidden = true
        linkIconButton.tintColor = .primary
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        buttonAction?()
    }
}
