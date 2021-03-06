//
//  SideMenuViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.11.2020.
//

import UIKit

class SideMenuViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var infoButton: UIButton!
    @IBOutlet private var versionLabel: UILabel!
    
    var shouldDisplayLine = false
    var selectedMenuOption: DrawerOption = .files
    
    private let tableViewData = TableViewData.drawerData
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        setupTableView()
        
        viewModel = AuthViewModel()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        tableView.backgroundColor = .primary
        
        titleLabel.font = Text.style8.font
        titleLabel.textColor = .white
        titleLabel.isHidden = true
        
        infoButton.setTitle(.manageArchives, for: [])
        infoButton.setFont(Text.style16.font)
        infoButton.setTitleColor(.white, for: [])
        infoButton.isHidden = true
        
        versionLabel.textColor = .white
        versionLabel.font = Text.style12.font
        versionLabel.text = "Version".localized() + " \(Bundle.release) (\(Bundle.build))"
        versionLabel.isHidden = true
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        shouldDisplayLine = isOpening
        titleLabel.isHidden = !isOpening
        versionLabel.isHidden = !isOpening
        
        tableView.reloadData()
    }
    
    fileprivate func showLogOutDialog() {
        showActionDialog(
            styled: .simple,
            withTitle: "Are you sure you want to log out?",
            positiveButtonTitle: .logOut,
            positiveAction: {
                self.logOut()
            },
            overlayView: nil)
    }
    
    fileprivate func logOut() {
        viewModel?.deletePushToken(then: { status in
            self.viewModel?.logout(then: { status in
                switch status {
                case .success:
                    UploadManager.shared.cancelAll()
                    
                    AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication)
                    
                case .error(let message):
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: message)
                    }
                }
            })
        })
    }
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let drawerSection = DrawerSection(rawValue: section) else { return 0 }
        
        return tableViewData[drawerSection]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerTableViewCell.self)) as? DrawerTableViewCell,
            let drawerSection = DrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            fatalError()
        }
        
        cell.updateCell(with: menuOption)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let drawerSection = DrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            fatalError()
        }
        
        if menuOption == selectedMenuOption {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let drawerSection = DrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            fatalError()
        }
        
        selectedMenuOption = menuOption
        handleMenuOptionTap(forOption: menuOption)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == DrawerSection.files.rawValue, shouldDisplayLine else { return nil }
        
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
        guard section == DrawerSection.files.rawValue, shouldDisplayLine else { return 0 }
        
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
            
        case .accountInfo:
            let newRootVC = UIViewController.create(withIdentifier: .accountInfo, from: .settings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .security:
            let newRootVC = UIViewController.create(withIdentifier: .accountSettings, from: .settings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .addStorage:
            guard let url = URL(string: APIEnvironment.defaultEnv.buyStorageURL) else { return }
            UIApplication.shared.open(url)
            
        case .activityFeed:
            let newRootVC = ActivityFeedViewController()
            newRootVC.viewModel = ActivityFeedViewModel()
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .invitations:
            guard
                let inviteVC = UIViewController.create(withIdentifier: .invitations, from: .invitations) as? InvitesViewController
            else {
                return
            }
            
            inviteVC.viewModel = InviteViewModel()
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: inviteVC)
            
        case .logOut:
            logOut()
        }
    }
    
    fileprivate func navigateToController(_ id: ViewControllerId, from storyboard: StoryboardName) {
        let newRootVC = UIViewController.create(withIdentifier: id, from: storyboard)
        AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
    }
}

enum DrawerSection: Int {
    case files
    case others
}
