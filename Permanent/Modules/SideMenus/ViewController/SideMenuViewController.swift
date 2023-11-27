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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        EventsManager.trackPageView(page: .ArchiveMenu)
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        tableView.backgroundColor = .primary
        
        tableView.separatorColor = .clear
        
        versionLabel.textColor = .white.withAlphaComponent(0.33)
        versionLabel.font = TextFontStyle.style12.font
        versionLabel.text = "v.".localized() + " \(Bundle.release) [\(Bundle.build)]"
        versionLabel.setTextSpacingBy(value: -0.12)
        
        footerBackgroundView.backgroundColor = .black.withAlphaComponent(0.20)
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: LeftSideHeaderTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LeftSideHeaderTableViewCell.self))
        
        tableView.tableFooterView = UIView()
        NotificationCenter.default.addObserver(forName: AuthViewModel.updateArchiveSettingsChevron, object: nil, queue: nil) { [self] notification in
            updateLeftSideMenu()
        }
        
        NotificationCenter.default.addObserver(forName: ArchivesViewModel.closeArchiveSettings, object: nil, queue: nil) { [self] notification in
            if let archiveSetingsWasPressed = viewModel?.archiveSetingsWasPressed, archiveSetingsWasPressed {
                viewModel?.archiveSetingsWasPressed = false
            }
        }
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
        var menuIndexPaths = [IndexPath(item: 1, section: 2), IndexPath(item: 2, section: 2)]
        var menuTitles = [DrawerOption.manageTags, DrawerOption.manageMembers]
        if let hasLegacyPermissions = viewModel?.hasLegacyPermissions(), hasLegacyPermissions {
            menuIndexPaths = [IndexPath(item: 1, section: 2), IndexPath(item: 2, section: 2), IndexPath(item: 3, section: 2)]
            menuTitles = [DrawerOption.manageTags, DrawerOption.manageMembers, DrawerOption.legacyPlanning]
        }
        tableView.beginUpdates()
        if let archiveSetingsWasPressed = viewModel?.archiveSetingsWasPressed {
            if archiveSetingsWasPressed {
                tableViewData[LeftDrawerSection.archiveSettings]?.append(contentsOf: menuTitles)
                tableView.insertRows(at: menuIndexPaths, with: .automatic)
            } else {
                tableViewData[LeftDrawerSection.archiveSettings]?.removeAll(where: { $0 == DrawerOption.manageMembers || $0 == DrawerOption.manageTags || $0 == DrawerOption.legacyPlanning })
                tableView.deleteRows(at: menuIndexPaths, with: .automatic)
            }
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
                tableViewCell.updateCell(with: menuOption, isExpanded: viewModel?.archiveSetingsWasPressed)
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
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case LeftDrawerSection.publicGallery.rawValue, LeftDrawerSection.header.rawValue:
            return 0
        case LeftDrawerSection.files.rawValue:
            return 40
        case LeftDrawerSection.archiveSettings.rawValue:
            return 40
        default:
            return 32
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == LeftDrawerSection.files.rawValue {
            return 4
        }
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
            viewModel?.archiveSetingsWasPressed.toggle()
            
        case .manageTags:
            let newRootVC = UIViewController.create(withIdentifier: .tagManagement, from: .archiveSettings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .manageMembers:
            let newRootVC = UIViewController.create(withIdentifier: .members, from: .members)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .legacyPlanning:
            if let archiveLegacyPlanningVC = UIViewController.create(withIdentifier: .legacyPlanningSteward, from: .legacyPlanning) as? LegacyPlanningStewardViewController, let archiveData = AuthenticationManager.shared.session?.selectedArchive {
                archiveLegacyPlanningVC.viewModel = LegacyPlanningViewModel()
                archiveLegacyPlanningVC.selectedArchive = archiveData
                archiveLegacyPlanningVC.viewModel?.stewardType = .archive
                let navControl = NavigationController(rootViewController: archiveLegacyPlanningVC)
                navControl.modalPresentationStyle = .fullScreen
                self.present(navControl, animated: true, completion: nil)
            }
            
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
