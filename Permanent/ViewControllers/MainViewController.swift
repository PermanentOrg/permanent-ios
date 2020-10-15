//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit

class MainViewController: BaseViewController<FilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        viewModel = FilesViewModel()
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
        backButton.tintColor = .primary
        backButton.isHidden = true
    }
    
    // MARK: - Actions
    
    private func getRoot() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
            
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool) {
        showSpinner()
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            
        })
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
        hideSpinner()
        
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
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.navigationStack.popLast(),
            let destinationFolder = viewModel.navigationStack.last
        else {
            return
        }
        
        // If we got to the root, hide the back button
        if viewModel.navigationStack.count == 1 {
            backButton.isHidden = true
        }
        
        directoryLabel.text = destinationFolder.name
        
        let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: true)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.viewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let viewModel = self.viewModel,
            let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableViewCell") as? FileTableViewCell
        else {
            fatalError()
        }
        
        let file = viewModel.viewModels[indexPath.row]
        cell.updateCell(model: file)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = viewModel else {
            fatalError()
        }
        
        let file = viewModel.viewModels[indexPath.row]
        guard file.type.isFolder else { return }
        
        backButton.isHidden = false
        directoryLabel.text = file.name
        
        let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: false)
    }
}
