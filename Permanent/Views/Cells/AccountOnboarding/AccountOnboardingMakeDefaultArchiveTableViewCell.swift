//
//  AccountOnboardingMakeDefaultArchiveTableViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.05.2022.
//

import UIKit

class AccountOnboardingMakeDefaultArchiveTableViewCell: UITableViewCell {
    static let identifier = "AccountOnboardingMakeDefaultArchiveTableViewCell"
    
    @IBOutlet weak var archiveThumbnailImageView: UIImageView!
    @IBOutlet weak var archiveTitleLabel: UILabel!
    @IBOutlet weak var archiveInvitedByLabel: UILabel!
    @IBOutlet weak var makeDefaultButton: RoundedButton!
    
    var makeDefaultButtonAction: ((AccountOnboardingMakeDefaultArchiveTableViewCell) -> Void)?
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
        
        makeDefaultButton.setup()
        makeDefaultButton.setTitleColor(UIColor.white.darker(by: 30), for: .disabled)
        makeDefaultButton.setTitleColor(UIColor.white, for: .highlighted)
        makeDefaultButton.configureActionButtonUI(title: "Make Default")
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
    
    @IBAction func makeDefaultAction(_ sender: Any) {
        makeDefaultButtonAction?(self)
    }
}
