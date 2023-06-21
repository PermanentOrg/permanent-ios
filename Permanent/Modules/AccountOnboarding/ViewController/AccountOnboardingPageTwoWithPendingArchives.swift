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
        welcomeLabel.font = TextFontStyle.style.font
        detailsLabel.font = TextFontStyle.style5.font
        
        detailsLabel.text = "Congratulations! You’ve joined \(viewModel?.accountArchives?.count ?? 0) archives. The last step is to choose which archive to set as your default, the first one you’ll see when you log in. Select your default archive below, or create a new one of your own to be your default."
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.allowsSelection = true
        
        tableView.register(UINib(nibName: String(describing: AccountOnboardingAcceptArchiveTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AccountOnboardingAcceptArchiveTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AccountOnboardingHeaderTableViewCell.self), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self))
    }
}

extension AccountOnboardingPageTwoWithPendingArchives: UITableViewDataSource, UITableViewDelegate {
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
            
            cell = tableViewCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewData = viewModel?.accountArchives, let archiveVOData = tableViewData[indexPath.row].archiveVO, let archiveId = archiveVOData.archiveID else { return }
        
        showSpinner()
        viewModel?.updateAccount(withDefaultArchiveId: archiveId, { [weak self] accountVOdata, error in
            guard accountVOdata != nil else {
                self?.hideSpinner()
                self?.showErrorAlert(message: .errorMessage)
                return
            }
            self?.viewModel?.changeArchive(archiveVOData, { status, error in
                self?.hideSpinner()

                if status {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    self?.showErrorAlert(message: .errorMessage)
                }
            })
        })
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: AccountOnboardingHeaderTableViewCell.self)) as? AccountOnboardingHeaderTableViewCell {
            headerCell.configure(label: "Choose a default archive".localized())
            headerView.addSubview(headerCell)
        }
        tableView.separatorInset.left = 0
        headerView.backgroundColor = .clear
        return headerView
    }
}
