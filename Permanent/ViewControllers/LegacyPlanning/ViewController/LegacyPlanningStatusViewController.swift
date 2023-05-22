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
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    func setupTableView() {
        tableView.register(UINib(nibName: String(describing: LegacyAccountStatusCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyAccountStatusCell.self))
        tableView.register(UINib(nibName: String(describing: LegacyArchiveCreateCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyArchiveCreateCell.self))
        tableView.register(UINib(nibName: String(describing: LegacyArchiveCompletedCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LegacyArchiveCompletedCell.self))
        
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.archives.count ?? 0 + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            cell = tableView.dequeue(cellClass: LegacyAccountStatusCell.self, forIndexPath: indexPath)
            
        } else {
            guard let archive = viewModel?.archives[indexPath.section] else {
                return cell
            }
            
            if archive.stewardName != nil {
                cell = tableView.dequeue(cellClass: LegacyArchiveCompletedCell.self, forIndexPath: indexPath)
                (cell as? LegacyArchiveCompletedCell)?.setup(directive: archive)
            } else {
                cell = tableView.dequeue(cellClass: LegacyArchiveCreateCell.self, forIndexPath: indexPath)
                (cell as? LegacyArchiveCreateCell)?.setup(directive: archive)
            }
        }
        cell.layer.backgroundColor = UIColor.clear.cgColor
        return cell
    }
}
