//
//  AccountOnboardingPageTwoWithPendingArchives.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.05.2022.
//

import UIKit

class AccountOnboardingPageTwoWithPendingArchives: BaseViewController<AccountOnboardingViewModel> {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupTableView()
    }
    
    private func initUI() {
        welcomeLabel.font = Text.style.font
        detailsLabel.font = Text.style5.font
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(UINib(nibName: String(describing: AccountOnboardingMakeDefaultArchiveTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AccountOnboardingMakeDefaultArchiveTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AccountOnboardingHeaderTableViewCell.self), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self))
    }
    
    private func makeDefaultButtonAction() -> ((AccountOnboardingMakeDefaultArchiveTableViewCell) -> Void) {
        return { [weak self] cell in
            self?.showSpinner()
            guard let archiveVOData = cell.archiveData,
                  let archiveId = archiveVOData.archiveID else { return }
            self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVOdata, error in
                guard let _ = accountVOdata else {
                    self?.hideSpinner()
                    self?.showErrorAlert(message: .errorMessage)
                    return
                }
                self?.viewModel?.changeArchive(archiveVOData, { status, error in
                    if status {
                        self?.hideSpinner()
                        self?.showAlert(title: .success, message: "Pending archive was accepted.".localized())
                        AppDelegate.shared.rootViewController.setDrawerRoot()
                    } else {
                        self?.hideSpinner()
                        self?.showErrorAlert(message: .errorMessage)
                    }
                })
            })
        }
    }
}

extension AccountOnboardingPageTwoWithPendingArchives: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfPendingArchives = viewModel?.accountArchives?.count else { return .zero }
        
        return numberOfPendingArchives
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountOnboardingMakeDefaultArchiveTableViewCell.self)) as? AccountOnboardingMakeDefaultArchiveTableViewCell,
           let tableViewData = viewModel?.accountArchives,
           let archiveVO = tableViewData[indexPath.row].archiveVO {
            tableViewCell.configure(archive: archiveVO)
            
            tableViewCell.makeDefaultButtonAction = makeDefaultButtonAction()
            
            cell = tableViewCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self)) as? AccountOnboardingHeaderTableViewCell {
            headerCell.configure(label: "Archive Name")
            headerView.addSubview(headerCell)
        }
        tableView.separatorInset.left = 0
        headerView.backgroundColor = .clear
        return headerView
    }
}
