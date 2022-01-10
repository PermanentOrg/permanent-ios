//
//  SideMenuViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.11.2020.
//

import UIKit

class SideMenuViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var versionLabel: UILabel!
    
    var selectedMenuOption: DrawerOption = .files
    
    private let tableViewData: [LeftDrawerSection: [DrawerOption]] = [
        LeftDrawerSection.header: [
            DrawerOption.archives
        ],
        
        LeftDrawerSection.leftFiles: [
            DrawerOption.files,
            DrawerOption.shares
        ],
        
        LeftDrawerSection.leftOthers: [
            DrawerOption.members,
            DrawerOption.profilePage
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = AuthViewModel()
        
        initUI()
        setupTableView()
        
        if viewModel?.getCurrentArchive() == nil {
            viewModel?.refreshCurrentArchive({ [self] archive in
                tableView.reloadRows(at: [[0,0]], with: .none)
            })
        }
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        tableView.backgroundColor = .primary
        
        tableView.separatorColor = .clear
        
        versionLabel.textColor = .white
        versionLabel.font = Text.style12.font
        versionLabel.text = "Version".localized() + " \(Bundle.release) (\(Bundle.build))"
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: LeftSideHeaderTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: LeftSideHeaderTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        tableView.reloadData()
        
        if (tableView.contentSize.height < tableView.frame.size.height) {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
    }
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let drawerSection = LeftDrawerSection(rawValue: section),
              let numberOfItems = tableViewData[drawerSection]?.count else {
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
        
        if menuOption == .archives {
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: LeftSideHeaderTableViewCell.self)) as? LeftSideHeaderTableViewCell {
                
                if let archive = viewModel?.getCurrentArchive(),
                   let archiveName: String = archive.fullName {
                    let archiveThumbURL: String = archive.thumbURL500 ?? ""
                    tableViewCell.updateCell(with: archiveThumbURL, archiveName: archiveName)
                    tableViewCell.isEnabled = true
                } else {
                    tableViewCell.isEnabled = false
                }
                
                cell = tableViewCell
            }
        } else {
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
        guard section == LeftDrawerSection.leftFiles.rawValue else {
            return nil
        }
        
        let headerView = UIView()
        
        let lineView = UIView()
        lineView.backgroundColor = .backgroundPrimary
        headerView.addSubview(lineView)
        
        lineView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 10),
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == LeftDrawerSection.leftFiles.rawValue else {
            return nil
        }
        
        let headerView = UIView()
        
        let lineView = UIView()
        lineView.backgroundColor = .backgroundPrimary
        headerView.addSubview(lineView)
        
        lineView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 10),
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == LeftDrawerSection.leftFiles.rawValue else { return 0 }
        
        return 21
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == LeftDrawerSection.leftFiles.rawValue else { return 0 }
        
        return 21
    }
    
    fileprivate func handleMenuOptionTap(forOption option: DrawerOption) {
        switch option {
        case .files:
            let newRootVC = UIViewController.create(withIdentifier: .main, from: .main)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .shares:
            let newRootVC = UIViewController.create(withIdentifier: .shares, from: .share)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .members:
            let newRootVC = UIViewController.create(withIdentifier: .members, from: .members)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)

        case .archives:
            let newRootVC = UIViewController.create(withIdentifier: .archives, from: .archives)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .profilePage:
            guard let archive = viewModel?.getCurrentArchive() else { return }
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = archive
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

enum LeftDrawerSection: Int {
    case header
    case leftFiles
    case leftOthers
}
