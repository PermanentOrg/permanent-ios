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
    
    func configure(archive: ArchiveVOData?) {
        guard let thumbnail = archive?.thumbURL1000,
            let name = archive?.fullName,
            let role = archive?.accessRole else { return }
        
        initUIforLocalArchive()
        
        archiveImage.load(urlString: thumbnail)
        archiveTitleLabel.text = name
        archiveUserRole.text = AccessRole.roleForValue(role).groupName
    }
    
    private func initUIforLocalArchive() {
        rightSideBackgroundView.backgroundColor = .primary
        
        archiveTitleLabel.textColor = .white
        archiveTitleLabel.font = Text.style9.font
        archiveUserRole.textColor = .white
        archiveUserRole.font = Text.style12.font
        linkIconButton.tintColor = .white
        linkIconButton.setAttributedTitle(NSAttributedString(string: "", attributes: [.font: Text.style17.font, .foregroundColor: UIColor.primary]), for: .normal)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        buttonAction?()
    }
}
