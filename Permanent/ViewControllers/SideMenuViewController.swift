//  
//  SideMenuViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.11.2020.
//

import UIKit

class SideMenuViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .systemRed
    }

}
