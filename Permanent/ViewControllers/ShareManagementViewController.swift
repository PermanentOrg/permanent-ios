//
//  ShareManagementViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.11.2022.
//

import UIKit

enum ShareManagementSectionType: Int {
    case title = 0
    case linkNotGenerated = 1
    case linkSection = 2
    case linkSettingsSection = 3
    case pendingRequests = 4
    case sharedWith = 5
    case buttons = 6
}

enum ShareManagementCellType {
    case title
    case linkNotGenerated
    case shareLink
    case linkSettings
    case sharePreview
    case autoApprove
    case defaultAccessRole
    case maxNumberOfUses
    case expirationDate
    case sendEmailInvitationOption
    case shareLinkOption
    case revokeLinkOption
    case sharedArchive
    case pendingArchive
}

class ShareManagementViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet weak var collectionView: UICollectionView!
    private let overlayView = UIView()
    
    var sharedFile: FileViewModel!
    var shareLink: String?
    var shareManagementViewData: [ShareManagementSectionType: [ShareManagementCellType]] = [:]
    
    var showLinkSettings: Bool?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedFile = viewModel?.fileViewModel
        
        initUI()
        initCollectionView()
        getShareLink(option: .retrieve)
        addDismissKeyboardGesture()
    }
    
    func initUI() {
        view.backgroundColor = .backgroundPrimary
        styleNavBar()
        
        addCustomNavigationBar()
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
    }
    
    func addCustomNavigationBar() {
        let imageView = UIView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let itemThumbImageView = UIImageView()
        itemThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        itemThumbImageView.contentMode = .scaleAspectFill
        itemThumbImageView.clipsToBounds = true
        imageView.addSubview(itemThumbImageView)
        
        if let isFolder = viewModel?.fileViewModel.type.isFolder, isFolder {
            itemThumbImageView.image = UIImage(named: "folderIcon")
            NSLayoutConstraint.activate([
                itemThumbImageView.heightAnchor.constraint(equalToConstant: 35),
                itemThumbImageView.widthAnchor.constraint(equalToConstant: 35),
                itemThumbImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 4)
            ])
        } else {
            itemThumbImageView.sd_setImage(with: URL(string: viewModel?.fileViewModel.thumbnailURL))
            NSLayoutConstraint.activate([
                itemThumbImageView.heightAnchor.constraint(equalToConstant: 30),
                itemThumbImageView.widthAnchor.constraint(equalToConstant: 30),
                itemThumbImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 0)
            ])
        }
        
        NSLayoutConstraint.activate([
            itemThumbImageView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            itemThumbImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])

        let itemNameLabel = UILabel()
        itemNameLabel.text = sharedFile.name
        itemNameLabel.textColor = .white
        itemNameLabel.font = Text.style3.font
        
        let headerStackView = UIStackView(arrangedSubviews: [imageView, itemNameLabel])
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.spacing = 16
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: headerStackView)
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        layout.minimumLineSpacing = 24

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .backgroundPrimary
        
        collectionView.register(ShareManagementTitleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementTitleCollectionViewCell.identifier)
        collectionView.register(ShareManagementLinkNotGeneratedCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementLinkNotGeneratedCollectionViewCell.identifier)
        collectionView.register(ShareManagementLinkAndShowSettingsCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier)
        collectionView.register(ShareManagementToggleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementToggleCollectionViewCell.identifier)
        collectionView.register(ShareManagementDefaultAccessRoleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementDefaultAccessRoleCollectionViewCell.identifier)
        collectionView.register(ShareManagementExpirationDateCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementExpirationDateCollectionViewCell.identifier)
        collectionView.register(ShareManagementNumberOfUsesCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementNumberOfUsesCollectionViewCell.identifier)
        collectionView.register(ShareMangementAdditionalOptionCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareMangementAdditionalOptionCollectionViewCell.identifier)
        collectionView.register(ShareManagementSharedWithCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementSharedWithCollectionViewCell.identifier)
    
        collectionView.register(ShareManagementEmptyHeaderCollectionReusableView.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ShareManagementEmptyHeaderCollectionReusableView.identifier)
        collectionView.register(ShareManagementHeaderCollectionReusableView.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ShareManagementHeaderCollectionReusableView.identifier)
        collectionView.register(ShareManagementSeparatorFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ShareManagementSeparatorFooterCollectionViewCell.identifier)
    }
    
    func initCollectionViewData() {
        shareManagementViewData = [:]
        
        if let _ = shareLink {
            if let showLinkSettings = showLinkSettings, showLinkSettings {
                shareManagementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
                shareManagementViewData[ShareManagementSectionType.linkSection] = [
                    ShareManagementCellType.shareLink,
                    ShareManagementCellType.linkSettings
                ]
                shareManagementViewData[ShareManagementSectionType.linkSettingsSection] = [
                    ShareManagementCellType.sharePreview,
                    ShareManagementCellType.autoApprove,
                    ShareManagementCellType.maxNumberOfUses,
                    ShareManagementCellType.expirationDate
                ]
                shareManagementViewData[ShareManagementSectionType.buttons] = [
                    ShareManagementCellType.shareLinkOption,
                    ShareManagementCellType.revokeLinkOption
                ]
            } else {
                shareManagementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
                shareManagementViewData[ShareManagementSectionType.linkSection] = [
                    ShareManagementCellType.shareLink,
                    ShareManagementCellType.linkSettings
                ]
                shareManagementViewData[ShareManagementSectionType.buttons] = [
                    ShareManagementCellType.shareLinkOption,
                    ShareManagementCellType.revokeLinkOption
                ]
            }
        } else {
            shareManagementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
            shareManagementViewData[ShareManagementSectionType.linkNotGenerated] = [ShareManagementCellType.linkNotGenerated]
        }
        
        if let shareVOs = viewModel?.acceptedShareVOs, shareVOs.isEmpty == false {
            shareManagementViewData[ShareManagementSectionType.sharedWith] = shareVOs.map({ _ in
                ShareManagementCellType.sharedArchive
            })
        }
        
        if let shareVOs = viewModel?.pendingShareVOs, shareVOs.isEmpty == false {
            shareManagementViewData[ShareManagementSectionType.pendingRequests] = shareVOs.map({ _ in
                ShareManagementCellType.pendingArchive
            })
        }

        collectionView.reloadData()
    }
    
    func insertLinkSettingsCells() {
        shareManagementViewData[ShareManagementSectionType.linkSettingsSection] = [
            ShareManagementCellType.sharePreview,
            ShareManagementCellType.autoApprove,
            ShareManagementCellType.maxNumberOfUses,
            ShareManagementCellType.expirationDate
        ]
        
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        if let sectionIndex = sections.firstIndex(of: .linkSettingsSection) {
            collectionView.insertSections([Int(sectionIndex)])
        }
    }
    
    func removeLinkSettingsCells() {
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        if let sectionIndex = sections.firstIndex(of: .linkSettingsSection) {
            shareManagementViewData.removeValue(forKey: .linkSettingsSection)
            
            collectionView.deleteSections([Int(sectionIndex)])
        }
    }
    
    func updateShowLinkSettings() {
        if showLinkSettings == nil {
            showLinkSettings = shareLink == nil ? true : false
        }
    }
    
    fileprivate func changeFilePermission(shareVO: ShareVOData, accessRole: AccessRole) {
        showSpinner()
        
        viewModel?.approveButtonAction(shareVO: shareVO, accessRole: accessRole, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                self.view.showNotificationBanner(title: "Access role was successfully changed".localized())
                
            case .error(let errorMessage):
                self.view.showNotificationBanner(title: errorMessage ?? .errorMessage, backgroundColor: .brightRed, textColor: .white)
            }

            self.getShareLink(option: .retrieve)
        })
        actionDialog?.dismiss()
        actionDialog = nil
    }
    
    func copyLinkAction() {
        var emailSubject = "<ACCOUNTNAME> wants to share an item from their Permanent Archive with you".localized()
        var emailBody = "<ACCOUNTNAME> wants to share an item from their Permanent Archive with you.\n <LINK>".localized()
        
        guard let link = shareLink,
              let name = viewModel?.getAccountName() else {
            return
        }
        emailSubject = emailSubject.replacingOccurrences(of: "<ACCOUNTNAME>", with: "\(name)")
        emailBody = emailBody.replacingOccurrences(of: "<ACCOUNTNAME>", with: "\(name)")
        emailBody = emailBody.replacingOccurrences(of: "<LINK>", with: "\(link)")
    
        let activityViewController = UIActivityViewController(activityItems: [emailBody], applicationActivities: nil)
        activityViewController.setValue(emailSubject, forKey: "Subject")
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    func editArchive(shareVO: ShareVOData) {
        guard let archiveVO = shareVO.archiveVO else { return }
        
        let accessRoles = AccessRole.allCases
            .filter { $0 != .manager }
            .map { $0.groupName }
        
        self.showActionDialog(
            styled: .dropdownWithDescription,
            withTitle: "The \(archiveVO.fullName ?? "") Archive",
            placeholders: [AccessRole.roleForValue(shareVO.accessRole ?? "").groupName],
            dropdownValues: accessRoles,
            positiveButtonTitle: "Update".localized(),
            positiveAction: { [weak self] in
                if let fieldsInput = self?.actionDialog?.fieldsInput,
                   let roleValue = fieldsInput.first {
                    let accessRole = AccessRole.roleForValue(AccessRole.apiRoleForValue(roleValue))
                    let fileTypeString: String = FileType(rawValue: shareVO.type ?? "")?.isFolder ?? false ? "folder" : "file"
                    if accessRole == .owner {
                        self?.actionDialog?.dismissPopup(
                            self?.actionDialog,
                            overlayView: self?.overlayView,
                            completion: { [weak self] _ in
                                self?.actionDialog?.removeFromSuperview()
                                self?.actionDialog = nil
                                guard var archiveName = archiveVO.fullName else { return }
                                archiveName = "The \(archiveName) Archive"
                                self?.showActionDialog(styled: .simpleWithDescription,
                                                       withTitle: "Add owner".localized(),
                                                       description: "Are you sure you want to share this \(fileTypeString) with <ARCHIVE_NAME> as an owner? This cannot be undone.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName),
                                                       positiveButtonTitle: "Add owner".localized(),
                                                       positiveAction: { [weak self] in
                                    self?.changeFilePermission(shareVO: shareVO, accessRole: accessRole)
                                }, overlayView: self?.overlayView)
                            }
                        )
                    } else {
                        self?.changeFilePermission(shareVO: shareVO, accessRole: accessRole)
                    }
                }
            },
            overlayView: self.overlayView
        )
    }
    
    // MARK: - Network Requests
    
    fileprivate func getShareLink(option: ShareLinkOption) {
        showSpinner()
        
        let group = DispatchGroup()
        
        group.enter()
        viewModel?.getShareLink(option: option, then: { shareVO, error in
            group.leave()
            
            guard error == nil else {
                return
            }
            
            guard
                let shareVO = shareVO,
                shareVO.sharebyURLID != nil,
                let shareURL = shareVO.shareURL
            else {
                return
            }
            
            self.shareLink = shareURL
        })
        
        if sharedFile.type.isFolder {
            group.enter()
            viewModel?.getFolder(then: { folderVO in
                group.leave()
            })
        } else {
            group.enter()
            viewModel?.getRecord(then: { recordVO in
                if recordVO == nil {
                    self.viewModel?.getFolder(then: { folderVO in
                        group.leave()
                    })
                } else {
                    group.leave()
                }
            })
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.hideSpinner()
            self.updateShowLinkSettings()
            self.initCollectionViewData()

        }
    }
    
    func revokeLinkAction() {
        showActionDialog(
            styled: .simple,
            withTitle: "\(String.revokeLink)?",
            positiveButtonTitle: .revoke,
            positiveAction: {
                self.actionDialog?.dismiss()
                self.revokeLink()
            },
            overlayView: overlayView
        )
    }
    
    fileprivate func revokeLink() {
        showSpinner()
        
        viewModel?.revokeLink(then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                self.shareLink = nil
                self.updateShowLinkSettings()
                self.initCollectionViewData()
               
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
}

extension ShareManagementViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        return shareManagementViewData[currentSection]?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return shareManagementViewData.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var returnedCell: UICollectionViewCell
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = shareManagementViewData[sections[indexPath.section]]![indexPath.row]
        
        switch currentCellType {
        case .title:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementTitleCollectionViewCell.identifier), for: indexPath) as! ShareManagementTitleCollectionViewCell
            cell.configure()
            returnedCell = cell
            
        case .linkNotGenerated:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementLinkNotGeneratedCollectionViewCell.identifier), for: indexPath) as! ShareManagementLinkNotGeneratedCollectionViewCell
            cell.buttonAction = {
                self.getShareLink(option: .create)
            }
            cell.imageView.isHidden = viewModel?.shareVOS?.isEmpty == false
            returnedCell = cell
            
        case .shareLink:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier), for: indexPath) as! ShareManagementLinkAndShowSettingsCollectionViewCell
            cell.configure(linkLocation: shareLink, cellType: currentCellType)
            
            cell.rightButtonAction = { [weak self] in
                self?.copyLinkAction()
            }
            returnedCell = cell
            
        case .linkSettings:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier), for: indexPath) as! ShareManagementLinkAndShowSettingsCollectionViewCell
            cell.configure(linkWasGeneratedNow: showLinkSettings ?? false, cellType: currentCellType)
            
            cell.leftButtonAction = { [weak self] in
                self?.showLinkSettings?.toggle()
                UIView.animate(withDuration: 0.2, animations: {
                    if self?.showLinkSettings == true {
                        cell.leftElementButton.transform = .identity.rotated(by: CGFloat.pi)
                    } else {
                        cell.leftElementButton.transform = .identity
                    }
                })
                if self?.showLinkSettings == true {
                    self?.insertLinkSettingsCells()
                } else {
                    self?.removeLinkSettingsCells()
                }
            }
            
            returnedCell = cell
            
        case .sharePreview, .autoApprove:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementToggleCollectionViewCell.identifier), for: indexPath) as! ShareManagementToggleCollectionViewCell
            cell.configure(cellType: currentCellType, viewModel: viewModel!)
            returnedCell = cell
            
        case .defaultAccessRole:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementDefaultAccessRoleCollectionViewCell.identifier), for: indexPath) as! ShareManagementDefaultAccessRoleCollectionViewCell
            cell.configure()
            returnedCell = cell
            
        case .maxNumberOfUses:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementNumberOfUsesCollectionViewCell.identifier), for: indexPath) as! ShareManagementNumberOfUsesCollectionViewCell
            cell.configure(viewModel: viewModel!)
            returnedCell = cell
            
        case .expirationDate:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementExpirationDateCollectionViewCell.identifier), for: indexPath) as! ShareManagementExpirationDateCollectionViewCell
            cell.configure(viewModel: viewModel!)
            returnedCell = cell
            
        case .sendEmailInvitationOption, .shareLinkOption, .revokeLinkOption:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareMangementAdditionalOptionCollectionViewCell.identifier), for: indexPath) as! ShareMangementAdditionalOptionCollectionViewCell
            cell.configure(cellType: currentCellType)
            returnedCell = cell
            
        case .sharedArchive:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementSharedWithCollectionViewCell.identifier), for: indexPath) as! ShareManagementSharedWithCollectionViewCell
            if let shareVO = viewModel?.acceptedShareVOs?[indexPath.row] {
                cell.configure(withShareVO: shareVO)
                
                cell.rightButtonAction = { [weak self] cell in
                    var actions = [
                        PRMNTAction(title: "Edit".localized(), iconName: "Rename", handler: { action in
                            self?.editArchive(shareVO: shareVO)
                        })
                    ]
                    
                    actions.insert(PRMNTAction(title: "Remove".localized(), iconName: "Delete-1", color: .brightRed, handler: { [weak self] action in
                        let description = "Are you sure you want to remove The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: shareVO.archiveVO?.fullName ?? "")
                        
                        self?.showActionDialog(
                            styled: .simpleWithDescription,
                            withTitle: description,
                            description: "",
                            positiveButtonTitle: "Remove".localized(),
                            positiveAction: { [weak self] in
                                self?.actionDialog?.dismiss()
                                self?.actionDialog = nil
                                
                                self?.showSpinner()
                                self?.viewModel?.denyButtonAction(shareVO: shareVO, then: { status in
                                    self?.hideSpinner()
                                    if status == .success {
                                        self?.view.showNotificationBanner(title: "Archive successfully removed".localized())
                                    } else {
                                        self?.view.showNotificationBanner(title: .errorMessage, backgroundColor: .brightRed, textColor: .white)
                                    }
                                    self?.getShareLink(option: .retrieve)
                                })
                            },
                            cancelButtonTitle: "Cancel".localized(),
                            positiveButtonColor: .brightRed,
                            cancelButtonColor: .primary,
                            overlayView: self?.overlayView
                        )
                    }), at: 0)
                    
                    let actionSheet = PRMNTActionSheetViewController(title: shareVO.archiveVO?.fullName, actions: actions)
                    self?.present(actionSheet, animated: true)
                }
            }
            
            returnedCell = cell
            
        case .pendingArchive:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementSharedWithCollectionViewCell.identifier), for: indexPath) as! ShareManagementSharedWithCollectionViewCell
            if let shareVO = viewModel?.pendingShareVOs?[indexPath.row] {
                cell.configure(withShareVO: shareVO)
                
                cell.rightButtonAction = { [weak self] _ in
                    self?.viewModel?.approveButtonAction(shareVO: shareVO, then: { status in
                        switch status {
                        case .success:
                            self?.view.showNotificationBanner(title: .approveShareRequest)
                            
                            self?.getShareLink(option: .retrieve)
                            self?.collectionView.reloadData()
                            
                        case .error(message: let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                }
                 
                cell.leftButtonAction = { [weak self] _ in
                    self?.viewModel?.denyButtonAction(shareVO: shareVO, then: { status in
                        switch status {
                        case .success:
                            self?.view.showNotificationBanner(title: .denyShareRequest)
                            
                            self?.getShareLink(option: .retrieve)
                            self?.collectionView.reloadData()
                            
                        case .error(message: let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                }
            }
            
            returnedCell = cell
        }
        
        return returnedCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = shareManagementViewData[sections[indexPath.section]]![indexPath.row]
        
        switch currentCellType {
        case .shareLinkOption:
            copyLinkAction()
        case .revokeLinkOption:
            revokeLinkAction()
        default: return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementSeparatorFooterCollectionViewCell.identifier, for: indexPath) as! ShareManagementSeparatorFooterCollectionViewCell
            return footerCell
            
        case UICollectionView.elementKindSectionHeader:
            let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
            let currentSection = sections[indexPath.section]
            
            switch currentSection {
            case .sharedWith:
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementHeaderCollectionReusableView.identifier, for: indexPath) as! ShareManagementHeaderCollectionReusableView
                headerCell.configure(withTitle: "Shared With".localized().uppercased(), badgeValue: viewModel?.acceptedShareVOs?.count ?? 0, isRedBadge: false)
                
                return headerCell
                
            case .pendingRequests:
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementHeaderCollectionReusableView.identifier, for: indexPath) as! ShareManagementHeaderCollectionReusableView
                headerCell.configure(withTitle: "PENDING REQUESTS".localized().uppercased(), badgeValue: viewModel?.pendingShareVOs?.count ?? 0, isRedBadge: true)
                
                return headerCell
                
            default:
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementEmptyHeaderCollectionReusableView.identifier, for: indexPath) as! ShareManagementEmptyHeaderCollectionReusableView
                return headerCell
            }
            
        default:
            return UICollectionReusableView()
        }
    }
}

extension ShareManagementViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cellSize = CGSize(width: collectionView.frame.width - 48, height: 0)
        
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = shareManagementViewData[sections[indexPath.section]]![indexPath.row]
        
        switch currentCellType {
        case .title:
            cellSize.height = 30
            
        case .linkNotGenerated:
            cellSize.height = viewModel?.shareVOS?.isEmpty == false ? 40 : 240
            
        case .shareLink, .linkSettings:
            cellSize.height = 24
            
        case .sharePreview , .autoApprove, .defaultAccessRole:
            cellSize.height = 40
            
        case .maxNumberOfUses, .expirationDate:
            cellSize.height = 70
            
        case .shareLinkOption, .sendEmailInvitationOption, .revokeLinkOption:
            cellSize.height = 20
            
        case .sharedArchive, .pendingArchive:
            cellSize.height = 40
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var cellSize = CGSize(width: collectionView.frame.width, height: 0)
        
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        switch currentSection {
        case .sharedWith:
            cellSize.height = (viewModel?.pendingShareVOs?.count ?? 0) == 0 ? 48 : 24
            
        case .pendingRequests:
            cellSize.height = (viewModel?.pendingShareVOs?.count ?? 0) > 0 ? 48 : 24
            
        default: return cellSize
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var cellSize = CGSize(width: collectionView.frame.width, height: 0)
        
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        switch currentSection {
        case .title:
            cellSize.height = 1
            
        case .linkNotGenerated:
            cellSize.height = viewModel?.shareVOS?.isEmpty == false ? 1 : 0
            
        case .linkSection:
            cellSize.height = (showLinkSettings ?? false) ? 0 : 1
            
        case .linkSettingsSection:
            cellSize.height = 1
            
        case .sharedWith:
            cellSize.height = 1
            
        default: return cellSize
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 24
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sections = Array(shareManagementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        switch currentSection {
        case .linkSettingsSection:
            return UIEdgeInsets(top: 0, left: 24, bottom: 24, right: 24)
        
        default:
            return UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        }
    }
}
