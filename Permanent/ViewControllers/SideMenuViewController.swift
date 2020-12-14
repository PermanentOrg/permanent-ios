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
    @IBOutlet private var infoButton: UIButton!
    
    var shouldDisplayLine = false
    
    private let tableViewData = TableViewData.drawerData
    
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
        titleLabel.isHidden = true
        
        infoButton.setTitle(.manageArchives, for: [])
        infoButton.setFont(Text.style17.font)
        infoButton.setTitleColor(.white, for: [])
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: DrawerTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: DrawerTableViewCell.self))
        
        tableView.tableFooterView = UIView()
    }
    
    func adjustUIForAnimation(isOpening: Bool) {
        self.shouldDisplayLine = isOpening
        self.titleLabel.isHidden = !isOpening
        self.infoButton.isHidden = !isOpening
        
        self.tableView.reloadData()
    }
}

extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let drawerSection = DrawerSection(rawValue: section) else { return 0 }
        
        return tableViewData[drawerSection]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerTableViewCell.self)) as? DrawerTableViewCell,
            let drawerSection = DrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            fatalError()
        }
        
        cell.updateCell(with: menuOption)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let drawerSection = DrawerSection(rawValue: indexPath.section),
            let menuOption = tableViewData[drawerSection]?[indexPath.row]
        else {
            fatalError()
        }
        
        if menuOption.title ==  .shares {
            let newRootVC = UIViewController.create(withIdentifier: .shares, from: .share)
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == DrawerSection.files.rawValue, shouldDisplayLine else { return nil }
        
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
        guard section == DrawerSection.files.rawValue, shouldDisplayLine else { return 0 }
        
        return 21
    }
}


enum DrawerSection: Int {
    case files
    case others
}
