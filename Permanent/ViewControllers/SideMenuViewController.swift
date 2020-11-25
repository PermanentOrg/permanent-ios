//  
//  SideMenuViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.11.2020.
//

import UIKit

class SideMenuViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        setupTableView()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        tableView.backgroundColor = .primary
        
        titleLabel.font = Text.style8.font
        titleLabel.textColor = .white
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }

    // MARK: - Actions
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerTableViewCell.self)) as? DrawerTableViewCell
        else {
            fatalError()
        }
        
        cell.backgroundColor = indexPath.row == 0 ? .mainPurple : .primary
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == DrawerSection.files.rawValue else { return nil }
        
        let headerView = UIView()
        
        let lineView = UIView()
        lineView.backgroundColor = .backgroundPrimary
        headerView.addSubview(lineView)
        
        lineView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor, constant: 10),
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == DrawerSection.files.rawValue else { return 0 }
        
        return 21
    }
}


enum DrawerSection: Int {
    case files
    case others // rename
}
