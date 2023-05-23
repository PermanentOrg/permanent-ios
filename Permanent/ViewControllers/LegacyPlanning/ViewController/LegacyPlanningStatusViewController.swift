//
//  LegacyStatusViewController.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//

import Foundation
import UIKit
import Combine

class LegacyPlanningStatusViewController: BaseViewController<LegacyPlanningStatusViewModel>, UITableViewDataSource {
    
    var cancellables: [AnyCancellable] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavBar()
    }
    
    func setupTableView() {
        tableView.register(UINib(nibName: String(describing: LegacyAccountStatusCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyAccountStatusCell.self))
        tableView.register(UINib(nibName: String(describing: LegacyArchiveCreateCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyArchiveCreateCell.self))
        tableView.register(UINib(nibName: String(describing: LegacyArchiveCompletedCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyArchiveCompletedCell.self))
        
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
        
        viewModel?.didLoad = {[weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = (viewModel?.legacyData.count ?? 0) + 1
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            cell = tableView.dequeue(cellClass: LegacyAccountStatusCell.self, forIndexPath: indexPath)
            
        } else {
            guard let data = viewModel?.legacyData[indexPath.section - 1] else {
                return cell
            }
            
            if data.steward != nil {
                cell = tableView.dequeue(cellClass: LegacyArchiveCompletedCell.self, forIndexPath: indexPath)
                (cell as? LegacyArchiveCompletedCell)?.setup(data: data)
            } else {
                cell = tableView.dequeue(cellClass: LegacyArchiveCreateCell.self, forIndexPath: indexPath)
                (cell as? LegacyArchiveCreateCell)?.setup(data: data)
            }
        }
        cell.layer.backgroundColor = UIColor.clear.cgColor
        return cell
    }
    
    // MARK: Setup Navigation
    
    private func setupNavBar() {
        titleLabelSetup()
        if let viewControllersCount = navigationController?.viewControllers.count, viewControllersCount > 1 {
            backButtonSetup()
        }
        closeButtonSetup()
    }
    
    private func titleLabelSetup() {
        let titleLabel = UILabel()
        titleLabel.text = "Legacy Planning".localized()
        titleLabel.textColor = .white
        titleLabel.font = TextFontStyle.style35.font
        titleLabel.sizeToFit()
        
        navigationItem.titleView = titleLabel
    }
    
    private func backButtonSetup() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(named: "newBackButton"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10)
        
        let backButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backButtonItem
    }
    
    private func closeButtonSetup() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(named: "newCloseButton"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -20)
        
        let closeButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.rightBarButtonItem = closeButtonItem
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
