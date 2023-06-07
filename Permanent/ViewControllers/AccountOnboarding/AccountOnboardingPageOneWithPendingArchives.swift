//
//  AccountOnboardingPageOneWithPendingArchives.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.05.2022.
//

import UIKit

class AccountOnboardingPageOneWithPendingArchives: BaseViewController<AccountOnboardingViewModel> {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupTableView()
    }
    
    private func initUI() {
        welcomeLabel.font = TextFontStyle.style.font
        detailsLabel.font = TextFontStyle.style5.font
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(UINib(nibName: String(describing: AccountOnboardingAcceptArchiveTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AccountOnboardingAcceptArchiveTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AccountOnboardingHeaderTableViewCell.self), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self))
    }
    
    private func acceptButtonAction() -> ((AccountOnboardingAcceptArchiveTableViewCell) -> Void) {
        return { [weak self] cell in
            self?.showSpinner()
            guard let archiveVOData = cell.archiveData else { return }
            
            self?.viewModel?.acceptArchiveOperation(archive: archiveVOData, { status, error in
                if status {
                    guard let archiveId = archiveVOData.archiveID else {
                        self?.hideSpinner()
                        self?.showErrorAlert(message: .errorMessage)
                        return
                    }
                    
                    self?.viewModel?.updateAccount(withDefaultArchiveId: archiveId, { accountVOdata, error in
                        guard let _ = accountVOdata else {
                            self?.hideSpinner()
                            self?.showErrorAlert(message: .errorMessage)
                            return
                        }
                        
                        self?.viewModel?.changeArchive(archiveVOData, { status, error in
                            self?.hideSpinner()
                            
                            if status {
                                UserDefaults.standard.set(1, forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
                                
                                AppDelegate.shared.rootViewController.setDrawerRoot()
                            } else {
                                self?.showErrorAlert(message: .errorMessage)
                            }
                        })
                    })
                } else {
                    self?.hideSpinner()
                    self?.showErrorAlert(message: .errorMessage)
                }
            })
        }
    }
}

extension AccountOnboardingPageOneWithPendingArchives: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfPendingArchives = viewModel?.accountArchives?.count else { return .zero }
        
        return numberOfPendingArchives
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountOnboardingAcceptArchiveTableViewCell.self)) as? AccountOnboardingAcceptArchiveTableViewCell,
           let tableViewData = viewModel?.accountArchives,
           let archiveVO = tableViewData[indexPath.row].archiveVO {
            tableViewCell.configure(archive: archiveVO, screenType: viewModel?.currentPage)
            
            tableViewCell.acceptButtonAction = acceptButtonAction()
            
            cell = tableViewCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self)) as? AccountOnboardingHeaderTableViewCell {
            headerCell.configure(label: "Pending invitations".localized())
            headerView.addSubview(headerCell)
        }
        tableView.separatorInset.left = 0
        headerView.backgroundColor = .clear
        return headerView
    }
}
