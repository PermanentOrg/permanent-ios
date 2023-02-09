//
//  SideMenuViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.11.2020.
//

import UIKit

enum LeftDrawerSection: Int {
    case header
    case files
    case archiveSettings
    case publicGallery
}

class SideMenuViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var versionLabel: UILabel!
    @IBOutlet weak var footerBackgroundView: UIView!
    
    var selectedMenuOption: DrawerOption = .files
    var archiveSetingsWasPressed: Bool = false {
        didSet {
            updateLeftSideMenu()
        }
    }
    static let updateArchiveSettingsChevron = Notification.Name("SideMenuViewController.updateArchiveSettingsChevron")
    
    private var tableViewData: [LeftDrawerSection: [DrawerOption]] = [
        LeftDrawerSection.header: [
            DrawerOption.archives
        ],
        LeftDrawerSection.files: [
            DrawerOption.files,
            DrawerOption.shares,
            DrawerOption.publicFiles
        ],
        LeftDrawerSection.archiveSettings: [
            DrawerOption.archiveSettings
        ],
        LeftDrawerSection.publicGallery: [
            DrawerOption.publicGallery
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = AuthViewModel()
        
        initUI()
        setupTableView()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        tableView.backgroundColor = .primary
        
        tableView.separatorColor = .clear
        
        versionLabel.textColor = .white.withAlphaComponent(0.33)
        versionLabel.font = Text.style12.font
        versionLabel.text = "v.".localized() + " \(Bundle.release) [\(Bundle.build)]"
        versionLabel.setTextSpacingBy(value: -0.12)
        
        footerBackgroundView.backgroundColor = .black.withAlphaComponent(0.20)
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: LeftSideHeaderTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LeftSideHeaderTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        tableView.reloadData()
        
        if tableView.contentSize.height < tableView.frame.size.height {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
    }
    
    func updateLeftSideMenu() {
        tableView.beginUpdates()
        NotificationCenter.default.post(name: Self.updateArchiveSettingsChevron, object: self, userInfo: nil)
        if archiveSetingsWasPressed {
            tableViewData[LeftDrawerSection.archiveSettings]?.append(contentsOf: [DrawerOption.tagsManagement, DrawerOption.usersManagement])
            tableView.insertRows(at: [IndexPath(item: 1, section: 2), IndexPath(item: 2, section: 2)], with: .automatic)
        } else {
            tableViewData[LeftDrawerSection.archiveSettings]?.removeAll(where: { $0 == DrawerOption.usersManagement || $0 == DrawerOption.tagsManagement })
            tableView.deleteRows(at: [IndexPath(item: 1, section: 2), IndexPath(item: 2, section: 2)], with: .automatic)
        }
        tableView.endUpdates()
    }
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let drawerSection = LeftDrawerSection(rawValue: section), let numberOfItems = tableViewData[drawerSection]?.count else {
            return 0
        }
        return numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        guard
            let drawerSection = LeftDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return UITableViewCell()
        }
        
        switch menuOption {
        case .archives:
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeftSideHeaderTableViewCell.self)) as? LeftSideHeaderTableViewCell {
                if let archive = viewModel?.getCurrentArchive(), let archiveName: String = archive.fullName {
                    let archiveThumbURL: String = archive.thumbURL500 ?? ""
                    tableViewCell.updateCell(with: archiveThumbURL, archiveName: archiveName)
                    tableViewCell.isEnabled = true
                } else {
                    tableViewCell.isEnabled = false
                }
                
                cell = tableViewCell
            }
        case .archiveSettings:
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerTableViewCell.self)) as? DrawerTableViewCell {
                tableViewCell.updateCell(with: menuOption, isExpanded: archiveSetingsWasPressed)
                cell = tableViewCell
            }
        default:
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerTableViewCell.self)) as? DrawerTableViewCell {
                tableViewCell.updateCell(with: menuOption)
                cell = tableViewCell
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let drawerSection = LeftDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return
        }
        
        if menuOption == selectedMenuOption {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard
            let drawerSection = LeftDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return true
        }
        
        if menuOption == .archives {
            let cell = tableView.cellForRow(at: indexPath) as? LeftSideHeaderTableViewCell
            return cell?.isEnabled ?? true
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let drawerSection = LeftDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return
        }
        
        selectedMenuOption = menuOption
        handleMenuOptionTap(forOption: menuOption)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        let lineView = UIView()
        lineView.backgroundColor = .white.withAlphaComponent(0.1)
        headerView.addSubview(lineView)
        
        lineView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
            headerView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 32),
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == LeftDrawerSection.publicGallery.rawValue || section == LeftDrawerSection.header.rawValue {
            return 0
        }
        
        return 32
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    fileprivate func handleMenuOptionTap(forOption option: DrawerOption) {
        switch option {
        case .files:
            let newRootVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
            newRootVC.viewModel = MyFilesViewModel()
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .publicFiles:
            let newRootVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
            newRootVC.viewModel = PublicFilesViewModel()
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .shares:
            let newRootVC = UIViewController.create(withIdentifier: .shares, from: .share)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .archiveSettings:
            archiveSetingsWasPressed.toggle()
            
        case .tagsManagement:
            let newRootVC = UIViewController.create(withIdentifier: .tagManagement, from: .archiveSettings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .usersManagement:
            let newRootVC = UIViewController.create(withIdentifier: .members, from: .members)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .archives:
            guard let archive = viewModel?.getCurrentArchive() else { return }
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = archive
            newRootVC.isViewingPublicProfile = true
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .publicGallery:
            let newRootVC = UIViewController.create(withIdentifier: .publicGallery, from: .main) as! PublicGalleryViewController
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        default:
            return
        }
    }
    
    fileprivate func navigateToController(_ id: ViewControllerId, from storyboard: StoryboardName) {
        let newRootVC = UIViewController.create(withIdentifier: id, from: storyboard)
        AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
    }
}
