//
//  WelcomePageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.07.2021.
//

import UIKit

class WelcomePageViewController: UIViewController  {
    var archiveName: String?
    
    @IBOutlet weak var welcomePageView: UIView!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var primaryLabelField: UILabel!
    @IBOutlet weak var secondaryLabelField: UILabel!
    @IBOutlet weak var acceptButton: RoundedButton!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    func initUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        welcomePageView.backgroundColor = .darkBlue
        welcomePageView.clipsToBounds = true
        welcomePageView.layer.cornerRadius = 10
        
        primaryLabelField.textColor = .white
        primaryLabelField.font = Text.style3.font
        primaryLabelField.numberOfLines = 2
        
        secondaryLabelField.textColor = .white
        secondaryLabelField.font = Text.style2.font
        secondaryLabelField.numberOfLines = 0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
        secondaryLabelField.addGestureRecognizer(tapGestureRecognizer)
        
        acceptButton.configureActionButtonUI(title: "Get Started".localized(), bgColor: .secondary, buttonHeight: 45)

        guard let currentArchive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive) else { return }
        let accessRole = AccessRole.roleForValue(currentArchive.accessRole ?? "")
        
        if accessRole == .owner {
            primaryLabelField.text = "Congratulations on your first archive!".localized()
        } else {
            primaryLabelField.text = "Invitation accepted!".localized()
        }
        
        let invitationsAccepted = UserDefaults.standard.integer(forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
        if invitationsAccepted == -1 {
            let text = "Your archive is <ARCHIVE_NAME>. You are the Owner of this archive.\n\nGet started by uploading your first files, or learn more about your new archive by viewing our help articles".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: "The \(currentArchive.fullName ?? "") Archive")
            
            let attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: UIColor.white, .font: Text.style2.font])
            let archiveNameRange = (text as NSString).range(of: "The \(currentArchive.fullName ?? "") Archive")
            attributedText.addAttribute(.font, value: Text.style17.font, range: archiveNameRange)
            secondaryLabelField.attributedText = attributedText
        } else if invitationsAccepted == 1 {
            let text = "Your archive is <ARCHIVE_NAME>.\n\nYou are <ROLE> of this archive. This means you can <PERMISSIONS> items within this archive. Read more about roles for collaboration and sharing.\n\nYou can manage any outstanding archive invitations through the menu in the upper left-hand corner.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: "The \(currentArchive.fullName ?? "") Archive").replacingOccurrences(of: "<ROLE>", with: role(accessRole)).replacingOccurrences(of: "<PERMISSIONS>", with: permissions(currentArchive))
            
            let attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: UIColor.white, .font: Text.style2.font])
            let archiveNameRange = (text as NSString).range(of: "The \(currentArchive.fullName ?? "") Archive")
            attributedText.addAttribute(.font, value: Text.style17.font, range: archiveNameRange)
            let roleRange = (text as NSString).range(of: "You are <ROLE> of this archive.".localized().replacingOccurrences(of: "<ROLE>", with: role(accessRole)))
            attributedText.addAttribute(.font, value: Text.style17.font, range: roleRange)
            let readMoreRange = (text as NSString).range(of: "Read more about roles for collaboration and sharing.".localized())
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: readMoreRange)
            attributedText.addAttribute(.foregroundColor, value: UIColor.secondary, range: readMoreRange)
            
            secondaryLabelField.attributedText = attributedText
        } else {
            let text = "Your default archive is <ARCHIVE_NAME>. You can change your archive settings at any time through the menu in the upper left-hand corner.\n\nYou are <ROLE> of this archive. This means you can <PERMISSIONS> items within this archive. Read more about roles for collaboration and sharing.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: "The \(currentArchive.fullName ?? "") Archive").replacingOccurrences(of: "<ROLE>", with: role(accessRole)).replacingOccurrences(of: "<PERMISSIONS>", with: permissions(currentArchive))
            
            let attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: UIColor.white, .font: Text.style2.font])
            let archiveNameRange = (text as NSString).range(of: "The \(currentArchive.fullName ?? "") Archive")
            attributedText.addAttribute(.font, value: Text.style17.font, range: archiveNameRange)
            let roleRange = (text as NSString).range(of: "You are <ROLE> of this archive.".localized().replacingOccurrences(of: "<ROLE>", with: role(accessRole)))
            attributedText.addAttribute(.font, value: Text.style17.font, range: roleRange)
            let readMoreRange = (text as NSString).range(of: "Read more about roles for collaboration and sharing.".localized())
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: readMoreRange)
            attributedText.addAttribute(.foregroundColor, value: UIColor.secondary, range: readMoreRange)
            
            secondaryLabelField.attributedText = attributedText
        }
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        closePopUp()
    }
    
    @IBAction func closeButton(_ sender: Any) {
        closePopUp()
    }
    
    @objc func tapGestureRecognized(_ recognizer: UITapGestureRecognizer) {
        guard let readMoreRange = (secondaryLabelField.attributedText?.string as NSString?)?.range(of: "Read more about roles for collaboration and sharing.".localized()) else { return }
        
        if recognizer.didTapAttributedText(inLabel: secondaryLabelField, inRange: readMoreRange),
           let url = URL(string: "https://desk.zoho.com/portal/permanent/en/kb/articles/roles-for-collaboration-and-sharing"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func closePopUp() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
        dismiss(animated: true, completion: nil)
    }
    
    func role(_ accessRole: AccessRole) -> String {
        switch accessRole {
        case .owner: return "the Owner".localized()
        
        case .manager: return "a Manager".localized()
            
        case .curator: return "a Curator".localized()
            
        case .editor: return "an Editor".localized()
            
        case .contributor: return "a Contribuitor".localized()
            
        case .viewer: return "a Viewer".localized()
        }
    }
    
    func permissions(_ archive: ArchiveVOData) -> String {
        var enumeratedPermissions = ""
        let permissionStrings = archive.permissions().compactMap(prettyPermission)
        for (idx, permission) in permissionStrings.enumerated() {
            if idx != permissionStrings.count - 1 {
                enumeratedPermissions += "\(permission), "
            } else {
                enumeratedPermissions += "and ".localized() + permission
            }
        }
        
        return enumeratedPermissions
    }
    
    func prettyPermission(_ permission: Permission) -> String? {
        switch permission {
        case .read: return "view".localized()
        
        case .create: return "create".localized()
            
        case .upload: return "upload".localized()
            
        case .edit: return "edit".localized()
            
        case .delete: return "delete".localized()
            
        case .move: return "move".localized()
            
        case .publish: return "publish".localized()
            
        case .share: return "share".localized()
            
        case .archiveShare, .ownership: return nil
        }
    }
}
