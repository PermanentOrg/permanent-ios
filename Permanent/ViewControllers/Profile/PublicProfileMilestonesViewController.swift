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
        cell.milestoneTitleLabel.text = item?.title
        
        cell.moreButtonAction = { [weak self] cell in
            let actionSheet = PRMNTActionSheetViewController(title: nil, actions: [
                PRMNTAction(title: "Delete".localized(), color: .brightRed, handler: { action in
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
