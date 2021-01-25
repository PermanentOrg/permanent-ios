//  
//  InvitationsViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import UIKit

class InvitationsViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var inviteButton: RoundedButton!
    @IBOutlet private var yourInvitationsLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupTableView()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
        navigationItem.title = .invitations
        
        titleLabel.style(withFont: Text.style9.font, textColor: .primary, text: .giveAGig)
        infoLabel.style(withFont: Text.style8.font, textColor: .textPrimary, text: .inviteInfo)
        yourInvitationsLabel.style(withFont: Text.style3.font, textColor: .primary, text: .yourInvitations)
        
        inviteButton.configureActionButtonUI(title: .sendInvite)
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: InvitationTableViewCell.self)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    
    @IBAction func inviteAction(_ sender: UIButton) {
    }

}

extension InvitationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: InvitationTableViewCell.self, forIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
