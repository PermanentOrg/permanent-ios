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
    
    override func loadView() {
        super.loadView()
        
        configureUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.start()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
    }
    
    fileprivate func setupTableView() {
        navigationItem.title = .activityFeed
    
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        tableView.registerNib(cellClass: NotificationTableViewCell.self)
        updateBackgroundView()
    }
    
    func updateBackgroundView() {
        if viewModel.numberOfItems == 0 {
            let emptyView = EmptyFolderView(title: "No notifications".localized(), image: .emptyNotification)
            emptyView.frame = tableView.bounds
            tableView.backgroundView = emptyView
        } else {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - Table View Delegate & Data Source

extension ActivityFeedViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: NotificationTableViewCell.self, forIndexPath: indexPath)
        cell.notification = viewModel.itemFor(row: indexPath.row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: ViewModel Delegate

extension ActivityFeedViewController: ActivityFeedViewModelViewDelegate {
    func updateScreen(status: RequestStatus) {
        updateBackgroundView()
        
        switch status {
        case .success:
            tableView.reloadData()
            
        case .error(_):
            break
        }
    }
    
    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
    }
}
