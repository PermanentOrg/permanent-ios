//
//  PublicProfileOnlinePresenceViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.01.2022.
//

import UIKit

class PublicProfileOnlinePresenceViewController: BaseViewController<PublicProfilePageViewModel> {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addEmailButton: RoundedButton!
    @IBOutlet weak var addLinkButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
    
        addEmailButton.configureActionButtonUI(title: "Add Email".localized())
        addLinkButton.configureActionButtonUI(title: "Add Link".localized())
        tableView.allowsSelection = false
        
        NotificationCenter.default.addObserver(forName: PublicProfilePageViewModel.profileItemsUpdatedNotificationName, object: nil, queue: nil) { [weak self] notification in
            self?.tableView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNavigationBar() {
        styleNavBar()
            
        title = "Edit Online Presence".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addEmailButtonPressed(_ sender: Any) {
        let vc = UIViewController.create(withIdentifier: .addOnlinePresence, from: .profile) as! PublicProfileAddOnlinePresenceViewController
        vc.viewModel = viewModel
        vc.fieldType = .email
        
        let navigationVC = NavigationController(rootViewController: vc)
        present(navigationVC, animated: true)
    }
    
    @IBAction func addLinkButtonPressed(_ sender: Any) {
        let vc = UIViewController.create(withIdentifier: .addOnlinePresence, from: .profile) as! PublicProfileAddOnlinePresenceViewController
        vc.viewModel = viewModel
        vc.fieldType = .socialMedia
        
        let navigationVC = NavigationController(rootViewController: vc)
        present(navigationVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PublicProfileOnlinePresenceViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel?.emailProfileItems.count ?? 0
        } else {
            return viewModel?.socialMediaProfileItems.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "linkCell") as! OnlinePresenceTableViewCell
        
        let item: ProfileItemModel?
        if indexPath.section == 0 {
            let emailItem = viewModel?.emailProfileItems[indexPath.row]
            cell.linkLabel.text = emailItem?.email
            
            item = emailItem
        } else {
            let linkItem = viewModel?.socialMediaProfileItems[indexPath.row]
            cell.linkLabel.text = linkItem?.link
            
            item = linkItem
        }
        
        cell.moreButtonAction = { [weak self] cell in
            let actionSheet = PRMNTActionSheetViewController(title: cell.linkLabel.text, actions: [
                PRMNTAction(title: "Delete".localized(), iconName: "Delete-1", color: .brightRed, handler: { action in
                    self?.showSpinner()
                    
                    if indexPath.section == 0 {
                        self?.viewModel?.modifyEmailProfileItem(profileItemId: item?.profileItemId, newValue: nil, operationType: .delete, { success, error, id in
                            self?.hideSpinner()
                        })
                    } else {
                        self?.viewModel?.modifySocialMediaProfileItem(profileItemId: item?.profileItemId, newValue: nil, operationType: .delete, { success, error, id in
                            self?.hideSpinner()
                        })
                    }
                }),
                PRMNTAction(title: "Edit".localized(), iconName: "Rename", handler: { action in
                    let vc = UIViewController.create(withIdentifier: .addOnlinePresence, from: .profile) as! PublicProfileAddOnlinePresenceViewController
                    vc.viewModel = self?.viewModel
                    vc.fieldType = indexPath.section == 0 ? .email : .socialMedia
                    vc.profileItem = item
                    
                    let navigationVC = NavigationController(rootViewController: vc)
                    self?.present(navigationVC, animated: true)
                })
            ])
            
            self?.present(actionSheet, animated: true, completion: nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let item = viewModel?.emailProfileItems[indexPath.row]
            
            if let emailString = item?.email, let url = URL(string: "mailto:" + emailString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            let item = viewModel?.socialMediaProfileItems[indexPath.row]
            
            if let url = URL(string: item?.link), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item: ProfileItemModel?
        if indexPath.section == 0 {
            let emailItem = viewModel?.emailProfileItems[indexPath.row]
            
            item = emailItem
        } else {
            let linkItem = viewModel?.socialMediaProfileItems[indexPath.row]
            
            item = linkItem
        }
        
        let deleteAction = UIContextualAction.make(
            withImage: .deleteActionRed,
            backgroundColor: .destructive,
            handler: {[weak self] _, _, completion in
                self?.showSpinner()
                
                if indexPath.section == 0 {
                    self?.viewModel?.modifyEmailProfileItem(profileItemId: item?.profileItemId, newValue: nil, operationType: .delete, { success, error, id in
                        self?.hideSpinner()
                    })
                } else {
                    self?.viewModel?.modifySocialMediaProfileItem(profileItemId: item?.profileItemId, newValue: nil, operationType: .delete, { success, error, id in
                        self?.hideSpinner()
                    })
                }
                completion(true)
            }
        )
        
        let editAction = UIContextualAction.make(
            withImage: .editActionFilled,
            backgroundColor: .primary,
            handler: {[weak self] _, _, completion in
                let vc = UIViewController.create(withIdentifier: .addOnlinePresence, from: .profile) as! PublicProfileAddOnlinePresenceViewController
                vc.viewModel = self?.viewModel
                vc.fieldType = indexPath.section == 0 ? .email : .socialMedia
                vc.profileItem = item
                
                let navigationVC = NavigationController(rootViewController: vc)
                self?.present(navigationVC, animated: true)
                completion(true)
            }
        )
        
        return UISwipeActionsConfiguration(actions: [
            editAction,
            deleteAction
        ])
    }
}
