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
}

class ShareManagementAccessRolesViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftButton: RoundedButton!
    @IBOutlet weak var rightButton: RoundedButton!
    
    private let overlayView = UIView()
    var shareManagementCellType: ShareManagementCellType!
    var sharedFile: FileViewModel!
    var shareVO: ShareVOData!
    var accessRolesViewData: [ShareManagementAccessRoleCellType] = []
    let isSharedArchive: Bool = true
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
    
    func initUI() {
        view.backgroundColor = .backgroundPrimary
        styleNavBar()
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        currentRole = ShareManagementAccessRoleCellType.cellTypeFromAccessRole(AccessRole.roleForValue(shareVO.accessRole))
        
    }
    
    func addCustomNavigationBar() {
        title = shareVO.archiveVO?.fullName
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
        if !isSharedArchive {
            accessRolesViewData.append(.removeShare)
        }
    }
    @IBAction func leftButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func rightButtonAction(_ sender: Any) {
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
}

extension ShareManagementAccessRolesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let currentCellType = accessRolesViewData[indexPath.row]
        var cellSize = CGSize(width: collectionView.frame.width - 24, height: 64)
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 21, left: 12, bottom: 0, right: 12)
    }
}
