//
//  ActivityFeedViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.01.2021.
//

import UIKit

class ActivityFeedViewController: UITableViewController {
    // MARK: - Properties
    
    var viewModel: ActivityFeedViewModelDelegate! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupTableView()
        viewModel.start()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
        
    }
    
    fileprivate func setupTableView() {
        
        navigationItem.title = .activityFeed
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        tableView.registerNib(cellClass: NotificationTableViewCell.self)
    }
}

extension ActivityFeedViewController: ActivityFeedViewModelViewDelegate {}

// MARK: - Table View Delegate & Data Source

extension ActivityFeedViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: NotificationTableViewCell.self, forIndexPath: indexPath)
        
        cell.notificationLabel.text = "Billy Beans Requested Access to “John and Sarah’s wedding Photos 2020"
        
        return cell
    }
}
