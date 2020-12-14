//  
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class SharesViewController: UIViewController {
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    private var tableViewData: [SharedFileData] = TableViewData.sharedByMeData
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setupTableView()
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
        configureTableViewBgView()
    }
    
    fileprivate func configureTableViewBgView() {
        if tableViewData.isEmpty {
            tableView.backgroundView = EmptyFolderView(title: .shareActionMessage, image: .shares)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            tableViewData = TableViewData.sharedByMeData
        } else {
            tableViewData = TableViewData.sharedWithMeData
        }
        
        self.tableView.reloadData()
        self.configureTableViewBgView()
    }
}

extension SharesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: SharedFileTableViewCell.self, forIndexPath: indexPath)
        
        let item = tableViewData[indexPath.row]
        cell.updateCell(model: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
