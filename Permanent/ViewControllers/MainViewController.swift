//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit

class MainViewController: BaseViewController<FilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        viewModel = FilesViewModel()
        tableView.delegate = viewModel
        tableView.dataSource = viewModel
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: nil), forCellReuseIdentifier: "fileTableViewCell")
        tableView.tableFooterView = UIView()
        
        getRoot()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = Translations.myFiles
        styleNavBar()
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
    }
    
    // MARK: - Actions
    
    private func getRoot() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.showAlert(title: Translations.error, message: message)
                }
            }
            
        })
    }
}
