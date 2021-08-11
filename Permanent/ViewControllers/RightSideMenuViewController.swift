//
//  RightSideMenuViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.08.2021.
//
import UIKit

class RightSideMenuViewController: BaseViewController<AuthViewModel> {
    
    @IBOutlet weak var loggedInLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var storageProgressBar: UIProgressView!
    @IBOutlet weak var storageUsedLabel: UILabel!
    @IBOutlet weak var separatorBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var shouldDisplayLine = false
    var selectedMenuOption: DrawerOption = .files
    
    static private let tableViewData: [DrawerSection: [DrawerOption]] = [
        DrawerSection.leftFiles: [
            DrawerOption.files,
            DrawerOption.shares
        ],
        
        DrawerSection.leftOthers: [
            DrawerOption.members
        ],
        
        DrawerSection.rightSideMenu: [
            DrawerOption.activityFeed,
            DrawerOption.invitations,
            DrawerOption.accountInfo,
            DrawerOption.security,
            DrawerOption.addStorage,
            DrawerOption.help,
            DrawerOption.logOut
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        setupTableView()
        
        viewModel = AuthViewModel()
    }
    
    func initUI() {
        storageProgressBar.isHidden = true
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: RightSideDrawerTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: RightSideDrawerTableViewCell.self))
        
    tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        view.shadowToBorder(showShadow: isOpening)
        shouldDisplayLine = isOpening
        storageProgressBar.isHidden = !isOpening
        
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

extension RightSideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
  //      guard let drawerSection = DrawerSection(rawValue: section) else { return 0 }
        return RightSideMenuViewController.tableViewData[DrawerSection.rightSideMenu]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RightSideDrawerTableViewCell.self)) as? RightSideDrawerTableViewCell,
            let menuOption = RightSideMenuViewController.tableViewData[DrawerSection.rightSideMenu]?[indexPath.row]
        else {
            return UITableViewCell()
        }
        cell.updateCell(with: menuOption)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let menuOption = RightSideMenuViewController.tableViewData[DrawerSection.rightSideMenu]?[indexPath.row]
        else {
            return
        }
        
        if menuOption == selectedMenuOption {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let menuOption = RightSideMenuViewController.tableViewData[DrawerSection.rightSideMenu]?[indexPath.row]
        else {
            return
        }
        
        selectedMenuOption = menuOption
        handleMenuOptionTap(forOption: menuOption)
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
            
        case .help:
            guard let url = URL(string: APIEnvironment.defaultEnv.helpURL) else { return }
            UIApplication.shared.open(url)
            
        case .logOut:
            logOut()
        }
    }
    
    fileprivate func navigateToController(_ id: ViewControllerId, from storyboard: StoryboardName) {
        let newRootVC = UIViewController.create(withIdentifier: id, from: storyboard)
        AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
    }
}
