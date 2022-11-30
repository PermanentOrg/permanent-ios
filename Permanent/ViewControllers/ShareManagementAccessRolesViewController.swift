//
//  ShareManagementAccessRolesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2022.
//

import UIKit

enum ShareManagementAccessRoleCellType: Int {
    case viewer = 0
    case contributor = 1
    case editor = 2
    case curator = 3
    case manager = 4
    case owner = 5
    case removeShare = 6
    
    static func roleToString(_ value: ShareManagementAccessRoleCellType) -> String? {
        switch value {
        case .viewer:
            return "Viewer"
        case .contributor:
            return "Contributor"
        case .editor:
            return "Editor"
        case .curator:
            return "Curator"
        case .manager:
            return "Manager"
        case .owner:
            return "Owner"
        case .removeShare:
            return "Remove Share"
        }
    }
    
    static func roleToPermissionString(_ value: ShareManagementAccessRoleCellType?) -> [String]? {
        switch value {
        case .viewer:
            return ["Read"]
        case .contributor:
            return ["Create","Read","Upload"]
        case .editor:
            return ["Create","Read","Edit","Upload"]
        case .curator:
            return ["Create","Read","Edit","Delete","Upload","Publish","Move","Share"]
        case .manager:
            return ["Create","Read","Edit","Delete","Upload","Publish","Move","Share","Archive Share Link"]
        case .owner:
            return ["Create","Read","Edit","Delete","Upload","Publish","Move","Share","Archive Share Link", "Ownership"]
        default:
            return nil
        }
    }
    
    static func cellTypeFromAccessRole(_ accessRole: AccessRole) -> ShareManagementAccessRoleCellType {
        switch accessRole {
        case .owner: return .owner
        case .manager: return .manager
        case .curator: return .curator
        case .editor: return .editor
        case .contributor: return .contributor
        case .viewer: return .viewer
        }
    }
    
    func accessRole() -> AccessRole? {
        switch self {
        case .owner: return .owner
        case .manager: return .manager
        case .curator: return .curator
        case .editor: return .editor
        case .contributor: return .contributor
        case .viewer: return .viewer
        default: return nil
        }
    }
}

class ShareManagementAccessRolesViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftButton: RoundedButton!
    @IBOutlet weak var rightButton: RoundedButton!
    
    private let overlayView = UIView()
    var shareManagementCellType: ShareManagementCellType!
    var sharedFile: FileViewModel!
    var shareVO: MinArchiveVO!
    var accessRolesViewData: [ShareManagementAccessRoleCellType] = []
    var isSharedArchive: Bool!
    var currentRole: ShareManagementAccessRoleCellType?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        addCustomNavigationBar()
        initCollectionView()
        initButtonsUI()
        initCollectionViewData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func initUI() {
        view.backgroundColor = .backgroundPrimary
        styleNavBar()
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        if shareVO != nil {
            currentRole = ShareManagementAccessRoleCellType.cellTypeFromAccessRole(AccessRole.roleForValue(shareVO.accessRole))
        } else {
            currentRole = ShareManagementAccessRoleCellType.cellTypeFromAccessRole(AccessRole.roleForValue(viewModel!.shareVO!.defaultAccessRole!))
        }
    }
    
    func addCustomNavigationBar() {
        let imageView = UIView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let itemThumbImageView = UIImageView()
        itemThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        itemThumbImageView.contentMode = .scaleAspectFill
        itemThumbImageView.clipsToBounds = true
        imageView.addSubview(itemThumbImageView)
        
        itemThumbImageView.image = UIImage(named: "archiveFolder")
        NSLayoutConstraint.activate([
            itemThumbImageView.heightAnchor.constraint(equalToConstant: 40),
            itemThumbImageView.widthAnchor.constraint(equalToConstant: 40),
            itemThumbImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 4)
        ])
        
        NSLayoutConstraint.activate([
            itemThumbImageView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            itemThumbImageView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])

        let itemNameLabel = UILabel()
        itemNameLabel.textColor = .white
        itemNameLabel.font = Text.style41.font
        
        let headerStackView: UIStackView
        if isSharedArchive {
            itemNameLabel.text = "The " + (shareVO.name) + " Archive"
            headerStackView = UIStackView(arrangedSubviews: [imageView, itemNameLabel])
        } else {
            itemNameLabel.text = "Link Settings".localized()
            headerStackView = UIStackView(arrangedSubviews: [itemNameLabel])
        }

        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.spacing = 6
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: headerStackView)
    }
    
    func initButtonsUI() {
        leftButton.bgColor = .whiteGray
        leftButton.titleLabel?.font = Text.style14.font
        leftButton.setTitleColor(.darkBlue, for: .normal)
        leftButton.setTitleColor(.darkBlue, for: .highlighted)
        leftButton.setTitle("Cancel".localized(), for: .normal)
        leftButton.layer.cornerRadius = 1
        
        rightButton.bgColor = .darkBlue
        rightButton.titleLabel?.font = Text.style14.font
        rightButton.setTitleColor(.white, for: .normal)
        rightButton.setTitleColor(.white, for: .highlighted)
        rightButton.setTitle("Update Role".localized(), for: .normal)
        rightButton.layer.cornerRadius = 1
    }
    
    func initCollectionView() {
        collectionView.backgroundColor = .backgroundPrimary
        
        collectionView.register(ShareManagementAccessRolesCollectionViewCell.nib(), forCellWithReuseIdentifier: ShareManagementAccessRolesCollectionViewCell.identifier)
        
        collectionView.register(ShareManagementAccessRolesHeaderCollectionReusableView.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ShareManagementAccessRolesHeaderCollectionReusableView.identifier)
    }
    
    func initCollectionViewData() {
        accessRolesViewData = [.viewer, .contributor, .editor, .curator, .manager, .owner]
        if isSharedArchive {
            accessRolesViewData.append(.removeShare)
        }
    }
    @IBAction func leftButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func rightButtonAction(_ sender: Any) {
        showSpinner()
        if isSharedArchive {
            if currentRole == .removeShare {
                viewModel?.denyButtonAction(minArchiveVO: shareVO, then: { status in
                    self.hideSpinner()
                    if status == .success {
                        self.view.showNotificationBanner(title: "Archive successfully removed".localized())
                    } else {
                        self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .brightRed, textColor: .white)
                    }
                })
            } else if let accessRole = currentRole?.accessRole() {
                viewModel?.approveButtonAction(minArchiveVO: shareVO, accessRole: accessRole, then: { status in
                    self.hideSpinner()
                    self.dismiss(animated: true)
                })
            }
        } else {
            if let accessRole = currentRole?.accessRole() {
                viewModel?.updateLinkWithChangedField(previewToggle: nil, autoApproveToggle: nil, expiresDT: nil, maxUses: nil, defaultAccessRole: accessRole, then: { _,_ in
                    self.hideSpinner()
                    self.dismiss(animated: true)
                })
            }
        }
    }
}

extension ShareManagementAccessRolesViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        accessRolesViewData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let currentCellType = accessRolesViewData[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShareManagementAccessRolesCollectionViewCell.identifier), for: indexPath) as! ShareManagementAccessRolesCollectionViewCell
        cell.configure(cellType: currentCellType, isSelected: currentRole == currentCellType)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCellType = accessRolesViewData[indexPath.row]
        
        currentRole = currentCellType
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareManagementAccessRolesHeaderCollectionReusableView.identifier, for: indexPath) as! ShareManagementAccessRolesHeaderCollectionReusableView
            headerCell.configure(hideContent: !isSharedArchive)
            headerCell.rightButtonTapped = { _ in
                guard let url = URL(string: APIEnvironment.defaultEnv.rolesMatrix) else { return }
                UIApplication.shared.open(url)
            }
            
            return headerCell
        default:
            return UICollectionReusableView()
        }
    }
}

extension ShareManagementAccessRolesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = CGSize(width: collectionView.frame.width - 24, height: 64)
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width - 24, height: 72)
    }
}
