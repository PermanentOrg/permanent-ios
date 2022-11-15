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
    case linkSettingsSection = 2
    case linkToggleSection = 3
    case optionalSettings = 4
    case shareLinkUserSpecificSettings = 5
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
}

class ShareManagementViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var sharedFile: FileViewModel!
    var shareLink: String?
    var shareMangementViewData: [ShareManagementSectionType: [ShareManagementCellType]] = [:]
    
    var showLinkSettings: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedFile = viewModel?.fileViewModel
        
        initUI()
        initCollectionView()
        getShareLink(option: .retrieve)
    }
    
    func initUI() {
        view.backgroundColor = .backgroundPrimary
        styleNavBar()
        
        navigationItem.title = sharedFile.name
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .backgroundPrimary
        collectionView.alwaysBounceVertical = true
        
        collectionView.register(ShareManagementTitleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementTitleCollectionViewCell.identifier)
        collectionView.register(ShareManagementLinkNotGeneratedCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementLinkNotGeneratedCollectionViewCell.identifier)
        collectionView.register(ShareManagementLinkAndShowSettingsCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier)
        collectionView.register(ShareManagementToggleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementToggleCollectionViewCell.identifier)
        collectionView.register(ShareManagementDefaultAccessRoleCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementDefaultAccessRoleCollectionViewCell.identifier)
        collectionView.register(ShareManagementExpirationDateCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementExpirationDateCollectionViewCell.identifier)
        collectionView.register(ShareMangementAdditionalOptionCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareMangementAdditionalOptionCollectionViewCell.identifier)
        
        collectionView.register(ShareManagementSeparatorFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ShareManagementSeparatorFooterCollectionViewCell.identifier)
    }
    
    func updateCollectionView() {
        shareMangementViewData = [
            ShareManagementSectionType.title: [
            ],
            ShareManagementSectionType.linkNotGenerated: [
            ],
            ShareManagementSectionType.linkSettingsSection: [
            ],
            ShareManagementSectionType.linkToggleSection: [
            ],
            ShareManagementSectionType.optionalSettings: [
            ],
            ShareManagementSectionType.shareLinkUserSpecificSettings: [
            ]
        ]
        
        
        if let _ = shareLink {
            if let showLinkSettings = showLinkSettings, showLinkSettings {
                shareMangementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
                shareMangementViewData[ShareManagementSectionType.linkSettingsSection] = [ShareManagementCellType.shareLink, ShareManagementCellType.linkSettings]
                //shareMangementViewData[ShareManagementSectionType.linkToggleSection] = [ ShareManagementCellType.sharePreview, ShareManagementCellType.autoApprove, ShareManagementCellType.defaultAccessRole]
                shareMangementViewData[ShareManagementSectionType.shareLinkUserSpecificSettings] = []
            } else {
                shareMangementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
                shareMangementViewData[ShareManagementSectionType.linkSettingsSection] = [ShareManagementCellType.shareLink, ShareManagementCellType.linkSettings]
            }
        } else {
            shareMangementViewData[ShareManagementSectionType.title] = [ShareManagementCellType.title]
            shareMangementViewData[ShareManagementSectionType.linkNotGenerated] = [ShareManagementCellType.linkNotGenerated]
        }
        
        collectionView.reloadData()
    }
    
    func updateShowLinkSettings() {
        if showLinkSettings == nil { showLinkSettings = shareLink == nil ? false : true }
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
            
            DispatchQueue.main.async {
                //self.createLinkButton.isHidden = true
                UIView.animate(
                    animations: {
                    //self.linkOptionsStackView.isHidden = false
                    }
                )
            }
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
            self.updateCollectionView()

        }
    }
    
    fileprivate func revokeLink() {
        showSpinner()
        
        viewModel?.revokeLink(then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                   // self.linkOptionsStackView.isHidden = true
                    UIView.animate(animations: {
                      //  self.createLinkButton.isHidden = false
                    })
                }
               
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
        let sections = Array(shareMangementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        return shareMangementViewData[currentSection]?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return shareMangementViewData.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var returnedCell: UICollectionViewCell
        let sections = Array(shareMangementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = shareMangementViewData[sections[indexPath.section]]![indexPath.row]
        
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
            returnedCell = cell
            
        case .shareLink, .linkSettings:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier), for: indexPath) as! ShareManagementLinkAndShowSettingsCollectionViewCell
            if currentCellType == .shareLink {
                cell.configure(linkLocation: shareLink)
            } else {
                cell.configure(linkWasGeneratedNow: showLinkSettings ?? false)
            }
            
            returnedCell = cell
        
        case .sharePreview, .autoApprove:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementLinkAndShowSettingsCollectionViewCell.identifier), for: indexPath) as! ShareManagementLinkAndShowSettingsCollectionViewCell
            if currentCellType == .shareLink {
                cell.configure(linkLocation: shareLink)
            } else {
                cell.configure(linkWasGeneratedNow: showLinkSettings ?? false)
            }
            
            returnedCell = cell
            
        case .defaultAccessRole:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementDefaultAccessRoleCollectionViewCell.identifier), for: indexPath) as! ShareManagementDefaultAccessRoleCollectionViewCell
            
            returnedCell = cell
            
        case .maxNumberOfUses:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementNumberOfUsesCollectionViewCell.identifier), for: indexPath) as! ShareManagementNumberOfUsesCollectionViewCell
            
            returnedCell = cell
            
        case .expirationDate:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementExpirationDateCollectionViewCell.identifier), for: indexPath) as! ShareManagementExpirationDateCollectionViewCell
            
            returnedCell = cell
        case .sendEmailInvitationOption, .shareLinkOption, .revokeLinkOption:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareMangementAdditionalOptionCollectionViewCell.identifier), for: indexPath) as! ShareMangementAdditionalOptionCollectionViewCell
            
            returnedCell = cell
        }
        
        return returnedCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementSeparatorFooterCollectionViewCell.identifier, for: indexPath) as! ShareManagementSeparatorFooterCollectionViewCell
            return footerCell
            
        default:
            return UICollectionReusableView()
        }
    }
}

extension ShareManagementViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cellSize = CGSize(width: collectionView.frame.width, height: 0)
        
        let sections = Array(shareMangementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = shareMangementViewData[sections[indexPath.section]]![indexPath.row]
        
        switch currentCellType {
        case .title:
            cellSize.height = 30
            
        case .linkNotGenerated:
            cellSize.height = 240
            
        case .shareLink:
            cellSize.height = 24
            
        case .shareLinkOption:
            cellSize.height = 24
            
        case .linkSettings, .sharePreview, .autoApprove, .defaultAccessRole, .maxNumberOfUses, .expirationDate, .sendEmailInvitationOption, .revokeLinkOption:
            cellSize.height = 0
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var cellSize = CGSize(width: collectionView.frame.width, height: 0)
        
        let sections = Array(shareMangementViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        switch currentSection {
        case .title, .optionalSettings:
            cellSize.height = 24
        default: return cellSize
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}
