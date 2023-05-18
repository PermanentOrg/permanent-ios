//
//  LegacyStatusViewController.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation
import UIKit

class LegacyStatusViewController: BaseViewController<LegacyPlanningViewModel>, UITableViewDataSource {
    
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeue(cellClass: LegacyAccountStatusCell.self, forIndexPath: indexPath)
            cell.layer.backgroundColor = UIColor.clear.cgColor
            return cell
        }
        if indexPath.section == 1 {
            let cell = tableView.dequeue(cellClass: LegacyArchiveCreateCell.self, forIndexPath: indexPath)
            cell.layer.backgroundColor = UIColor.clear.cgColor
            return cell
        }
        
        let cell = tableView.dequeue(cellClass: LegacyArchiveCompletedCell.self, forIndexPath: indexPath)
        cell.layer.backgroundColor = UIColor.clear.cgColor
        return cell
    }
}
