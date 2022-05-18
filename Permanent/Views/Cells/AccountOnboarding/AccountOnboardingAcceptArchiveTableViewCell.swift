//
//  AccountOnboardingAcceptArchiveTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.05.2022.
//

import UIKit

class AccountOnboardingAcceptArchiveTableViewCell: UITableViewCell {
    static let identifier = "AccountOnboardingAcceptArchiveTableViewCell"
    @IBOutlet weak var archiveThumbnailImageView: UIImageView!
    @IBOutlet weak var archiveTitleLabel: UILabel!
    @IBOutlet weak var archiveInvitedByLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    
    var acceptButtonAction: ((AccountOnboardingAcceptArchiveTableViewCell) -> Void)?
    var archiveData: ArchiveVOData?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(archive: ArchiveVOData?) {
        initUI()
        archiveData = archive
        if let name = archive?.fullName {
            archiveTitleLabel.text = "The \(name) Archive"
        } else {
            archiveTitleLabel.text = "The Archive"
        }
        
        guard let thumbnail = archive?.thumbURL1000 else { return }
        let role = archive?.accessRole ?? ""
        let accessRole = AccessRole.roleForValue(role).groupName
        let textLabel = "Pending Archive \nAccess: <ROLE>".localized().replacingOccurrences(of: "<ROLE>", with: accessRole)
        
        archiveThumbnailImageView.sd_setImage(with: URL(string: thumbnail))

        archiveInvitedByLabel.text = textLabel
    }
    
    private func initUI() {
        archiveTitleLabel.textColor = .black
        archiveTitleLabel.font = Text.style17.font
        archiveInvitedByLabel.textColor = .darkGray
        archiveInvitedByLabel.font = Text.style8.font
        
        acceptButton.setFont(Text.style11.font)
        acceptButton.setTitleColor(.darkBlue, for: .normal)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        archiveTitleLabel.text = "The Archive"
        archiveInvitedByLabel.text = ""
        archiveThumbnailImageView.image = .placeholder
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    @IBAction func acceptAction(_ sender: Any) {
        acceptButtonAction?(self)
    }
}
