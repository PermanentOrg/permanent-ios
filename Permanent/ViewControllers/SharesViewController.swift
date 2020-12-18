//  
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class SharesViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ShareLinkViewModel()
        
        configureUI()
        setupTableView()
     
        getShares()
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .shares
        view.backgroundColor = .backgroundPrimary
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white,
                                                 .font: Text.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: Text.style8.font], for: .normal)
        segmentedControl.setTitle(.sharedByMe, forSegmentAt: 0)
        segmentedControl.setTitle(.sharedWithMe, forSegmentAt: 1)
        
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .primary
        }
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: SharedFileTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
    }
    
    fileprivate func configureTableViewBgView() {
        if let items = viewModel?.items, items.isEmpty {
            tableView.backgroundView = EmptyFolderView(title: .shareActionMessage, image: .shares)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    fileprivate func refreshTableView() {
        self.tableView.reloadData()
        self.configureTableViewBgView()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let listType = ShareListType(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        viewModel?.shareListType = listType
        refreshTableView()
    }

    fileprivate func getShares() {
        showSpinner()
        viewModel?.getShares(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
}

extension SharesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = self.viewModel else {
            fatalError()
        }
        
        let cell = tableView.dequeue(cellClass: SharedFileTableViewCell.self, forIndexPath: indexPath)
        let item = viewModel.items[indexPath.row]
        cell.updateCell(model: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

