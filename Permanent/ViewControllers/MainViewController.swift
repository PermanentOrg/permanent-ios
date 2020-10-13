//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit

class MainViewController: BaseViewController<MyFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        viewModel = MyFilesViewModel()
        tableView.delegate = viewModel
        tableView.dataSource = viewModel
        
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: nil), forCellReuseIdentifier: "fileTableViewCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = "My Files"
        styleNavBar()
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
    }
}
