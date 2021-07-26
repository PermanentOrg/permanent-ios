//
//  InvitationsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import UIKit

class InvitesViewController: ViewController {
    // MARK: - Properties
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var inviteButton: RoundedButton!
    @IBOutlet private var yourInvitationsLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    
    var viewModel: InviteViewModelDelegate! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupTableView()
        viewModel.start()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
        navigationItem.title = .invitations
        
        titleLabel.style(withFont: Text.style9.font, textColor: .primary, text: .giveAGig)
        infoLabel.style(withFont: Text.style8.font, textColor: .textPrimary, text: .inviteInfo)
        yourInvitationsLabel.style(withFont: Text.style3.font, textColor: .primary, text: .yourInvitations)
        
        inviteButton.configureActionButtonUI(title: .sendInvite)
        
        setupOverlayView()
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: InvitationTableViewCell.self)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    
    @IBAction func inviteAction(_ sender: UIButton) {
        showActionDialog(
            styled: .multipleFields,
            withTitle: .sendInvitation,
            placeholders: [.recipientName, .recipientEmail],
            positiveButtonTitle: .send,
            positiveAction: {
                self.viewModel.sendInvite(info: self.actionDialog?.fieldsInput)
            })
    }
}

extension InvitesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: InvitationTableViewCell.self, forIndexPath: indexPath)
        
        let invite = viewModel.itemFor(row: indexPath.row)
        cell.invite = invite
        
        cell.resendAction = {
            self.viewModel.handleInvite(operation: .resend(id: invite.id))
        }
        
        cell.revokeAction = {
            self.viewModel.handleInvite(operation: .revoke(id: invite.id))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension InvitesViewController: InviteViewModelViewDelegate {
    func refreshList(afterOperation operation: InviteOperation, status: RequestStatus) {
        switch status {
        case .success:
            viewModel.start()
            view.showNotificationBanner(title: operation.infoText)
        
        case .error(_):
            break
        }
    }
    
    func updateScreen(status: RequestStatus) {
        switch status {
        case .success:
            yourInvitationsLabel.isHidden = !viewModel.hasData
            tableView.reloadData()
            
        case .error(_):
            break
        }
    }

    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
    }
    
    func dismissDialog() {
        actionDialog?.dismiss()
    }
}
