//
//  PublicProfileMilestonesViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.02.2022.
//

import UIKit

class PublicProfileMilestonesViewController: BaseViewController<PublicProfilePageViewModel> {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addMilestoneButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupNavigationBar()
        
        NotificationCenter.default.addObserver(forName: PublicProfilePageViewModel.profileItemsUpdatedNotificationName, object: nil, queue: nil) { [weak self] notification in
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    func initUI() {
        addMilestoneButton.configureActionButtonUI(title: "Add Milestone".localized())
        tableView.allowsSelection = false
    }
    
    func setupNavigationBar() {
        styleNavBar()
            
        title = "Edit Milestones".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addMilestoneButton(_ sender: Any) {
        let vc = UIViewController.create(withIdentifier: .addMilestones, from: .profile) as! PublicProfileAddMilestonesViewController
        vc.viewModel = viewModel

        let navigationVC = NavigationController(rootViewController: vc)
        present(navigationVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PublicProfileMilestonesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.milestonesProfileItems.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "milestoneCell") as! MilestonesTableViewCell
        
        let item = viewModel?.milestonesProfileItems[indexPath.row]
        cell.configure(milestone: item)
        
        cell.moreButtonAction = { [weak self] cell in
            let actionSheet = PRMNTActionSheetViewController(title: nil, actions: [
                PRMNTAction(title: "Delete".localized(), color: .brightRed, handler: { action in
                    self?.showSpinner()
                    
                    self?.viewModel?.deleteMilestoneProfileItem(milestone: item, { status in
                        self?.hideSpinner()
                        if status {
                            tableView.reloadData()
                        } else {
                            self?.showAlert(title: .error, message: .errorMessage)
                        }
                    })
                }),
                PRMNTAction(title: "Edit".localized(), handler: { action in
                    let vc = UIViewController.create(withIdentifier: .addMilestones, from: .profile) as! PublicProfileAddMilestonesViewController
                    vc.viewModel = self?.viewModel
                    vc.milestone = item
                    
                    let navigationVC = NavigationController(rootViewController: vc)
                    self?.present(navigationVC, animated: true)
                })
            ])
            
            self?.present(actionSheet, animated: true, completion: nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = viewModel?.milestonesProfileItems[indexPath.row]
        
        let deleteAction = UIContextualAction.make(
            withImage: .deleteActionRed,
            backgroundColor: .destructive,
            handler: {[weak self] _, _, completion in
                self?.showSpinner()
                
                self?.viewModel?.deleteMilestoneProfileItem(milestone: item, { status in
                    self?.hideSpinner()
                    if status {
                        tableView.reloadData()
                    } else {
                        self?.showAlert(title: .error, message: .errorMessage)
                    }
                })
                completion(true)
            }
        )
    
        let editAction = UIContextualAction.make(
            withImage: .editActionFilled,
            backgroundColor: .primary,
            handler: {[weak self] _, _, completion in
                let vc = UIViewController.create(withIdentifier: .addMilestones, from: .profile) as! PublicProfileAddMilestonesViewController
                vc.viewModel = self?.viewModel
                vc.milestone = item
                
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
