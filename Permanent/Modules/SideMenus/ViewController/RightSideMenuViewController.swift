//
//  RightSideMenuViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.08.2021.
//
import UIKit
import SwiftUI

enum RightDrawerSection: Int {
    case rightSideMenu
    case rightOthers
}

class RightSideMenuViewController: BaseViewController<AuthViewModel> {
    @IBOutlet weak var loggedInLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var storageProgressBar: UIProgressView!
    @IBOutlet weak var storageUsedLabel: UILabel!
    @IBOutlet weak var separatorBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var selectedMenuOption: DrawerOption = .none
    
    private let tableViewData: [RightDrawerSection: [DrawerOption]] = [
        RightDrawerSection.rightSideMenu: [
            DrawerOption.addStorage,
            DrawerOption.giftStorage,
            DrawerOption.accountInfo,
            DrawerOption.legacyPlanning,
            DrawerOption.activityFeed,
            DrawerOption.manageArchives,
            DrawerOption.invitations,
            DrawerOption.security,
            DrawerOption.contactSupport,
            DrawerOption.logOut
        ],
        
        RightDrawerSection.rightOthers: [
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AuthViewModel()
        
        initUI()
        
        setupTableView()
    }
    
    func initUI() {
        view.backgroundColor = .white
        tableView.backgroundColor = .white
        
        tableView.separatorColor = .clear
        
        storageProgressBar.tintColor = .mainPurple
        
        loggedInLabel.text = "Logged in as".localized() + ":"
        loggedInLabel.font = TextFontStyle.style8.font
        loggedInLabel.textColor = .middleGray
        
        emailLabel.font = TextFontStyle.style11.font
        emailLabel.textColor = .middleGray
        
        storageUsedLabel.font = TextFontStyle.style11.font
        storageUsedLabel.textColor = .middleGray
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: RightSideDrawerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: RightSideDrawerTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        tableView.reloadData()
        
        if tableView.contentSize.height < tableView.frame.size.height {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
        
        if isOpening {
            updateAccountInfo()
        }
    }
    
    fileprivate func updateAccountInfo() {
        viewModel?.getAccountInfo { [self] accountData, error in
            guard let accountData = accountData else { return }
            
            viewModel?.accountData = accountData
            
            let spaceTotal = (accountData.spaceTotal ?? 0)
            let spaceLeft = (accountData.spaceLeft ?? 0)
            let spaceUsed = spaceTotal - spaceLeft
            
            let spaceTotalHumanReadableContent = spaceTotal.bytesToReadableForm(useDecimal: false)
            let spaceUsedHumanReadableContent = spaceUsed.bytesToReadableForm()
            
            let storageLabelString = "<STORAGE_USED> of <STORAGE_TOTAL> used".localized().replacingOccurrences(of: "<STORAGE_USED>", with: spaceUsedHumanReadableContent).replacingOccurrences(of: "<STORAGE_TOTAL>", with: spaceTotalHumanReadableContent)
            storageUsedLabel.text = storageLabelString
            
            storageProgressBar.setProgress(Float(spaceUsed) / Float(spaceTotal), animated: true)
            
            emailLabel.text = accountData.primaryEmail
        }
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let drawerSection = RightDrawerSection(rawValue: section),
            let numberOfItems = tableViewData[drawerSection]?.count else { return 0 }
        return numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RightSideDrawerTableViewCell.self)) as? RightSideDrawerTableViewCell,
            let drawerSection = RightDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return UITableViewCell()
        }
        
        cell.updateCell(with: menuOption)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let drawerSection = RightDrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            return
        }
        
        if menuOption == selectedMenuOption {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let drawerSection = RightDrawerSection(rawValue: indexPath.section),
            let sectionData = tableViewData[drawerSection]
        else {
            return
        }
        let menuOption = sectionData[indexPath.row]
        
        let previousMenuOption = selectedMenuOption
        if menuOption != .contactSupport {
            selectedMenuOption = menuOption
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if previousMenuOption != .none {
                let previousIndexPath: IndexPath = [0, sectionData.firstIndex(of: previousMenuOption)!]
                tableView.selectRow(at: previousIndexPath, animated: true, scrollPosition: .none)
            }
        }
        
        handleMenuOptionTap(forOption: menuOption)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == RightDrawerSection.rightOthers.rawValue else {
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
        guard section == RightDrawerSection.rightOthers.rawValue else { return 0 }
        
        return 21
    }
    
    fileprivate func handleMenuOptionTap(forOption option: DrawerOption) {
        switch option {
        case .accountInfo:
            let newRootVC = UIViewController.create(withIdentifier: .accountInfo, from: .settings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .legacyPlanning:
            if let legacyPlanningLoadingVC = UIViewController.create(withIdentifier: .legacyPlanningLoading, from: .legacyPlanning) as? LegacyPlanningLoadingViewController {
                legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
                legacyPlanningLoadingVC.viewModel?.account = AuthenticationManager.shared.session?.account
                let customNavController = NavigationController(rootViewController: legacyPlanningLoadingVC)
                customNavController.modalPresentationStyle = .fullScreen
                self.present(customNavController, animated: true, completion: nil)
            }
        
        case .manageArchives:
            let newRootVC = UIViewController.create(withIdentifier: .archives, from: .archives)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .security:
            let newRootVC = UIViewController.create(withIdentifier: .accountSettings, from: .settings)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .addStorage:
            let newRootVC = UIViewController.create(withIdentifier: .donate, from: .donate)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            
        case .giftStorage:
            let hostingController = UIHostingController(rootView: GiftStorageView(viewModel: StateObject(wrappedValue: GiftStorageViewModel.init(accountData: self.viewModel?.accountData))))
            hostingController.modalPresentationStyle = .fullScreen
            
            self.present(hostingController, animated: true, completion: nil)
            
            // Add a way to call the completion block when the view is dismissed.
            hostingController.rootView.dismissAction = { hasUpdates in
                hostingController.dismiss(animated: true, completion: {
                    self.updateAccountInfo()
                    self.selectedMenuOption = .none
                    self.setupTableView()
                    self.adjustUIForAnimation(isOpening: false)
                })
            }
            
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
            
        case .contactSupport:
            guard let url = URL(string: APIEnvironment.defaultEnv.helpURL) else { return }
            UIApplication.shared.open(url)
            
        case .logOut:
            logOut()
            
        default:
            break
        }
    }
    
    fileprivate func navigateToController(_ id: ViewControllerId, from storyboard: StoryboardName) {
        let newRootVC = UIViewController.create(withIdentifier: id, from: storyboard)
        AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
    }
}
