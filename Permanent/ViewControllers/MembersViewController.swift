//  
//  MembersViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class MembersViewController: BaseViewController<MembersViewModel> {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addMembersButton: RoundedButton!
    
    private let overlayView = UIView()
    
    lazy var tooltipView = TooltipView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = MembersViewModel()
        
        configureUI()
        setupTableView()
        
        getMembers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    fileprivate func configureUI() {
        navigationItem.title = String.member.pluralized()
        view.backgroundColor = .backgroundPrimary
        addMembersButton.configureActionButtonUI(title: String.addMember.pluralized())
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0.0
    }
    
    fileprivate func setupTableView() {
        tableView.register(cellClass: MemberTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 80
        tableView.sectionFooterHeight = 1
    }
    
    @IBAction func addMembersAction(_ sender: UIButton) {
        
        let accessRoles = AccessRole.allCases
            .filter { $0 != .owner }
            .map { $0.groupName }
        
        self.showActionDialog(
            styled: .inputWithDropdown,
            withTitle: .addMember,
            placeholders: [.memberEmail, .accessLevel],
            dropdownValues: accessRoles,
            positiveButtonTitle: .save,
            positiveAction: {
                self.addMember()
            },
            overlayView: self.overlayView)
    }
    
    fileprivate func showTooltip(anchorPoint: CGPoint, text: String) {
    
        // Check if tooltip view is already presented on screen.
        // If it is visible, we remove it, before presenting it to the new location.
        if tooltipView.isDescendant(of: view) {
            tooltipView.removeFromSuperview()
        }
        
        tooltipView.text = text
        view.addSubview(tooltipView)
        tooltipView.enableAutoLayout()
        
        NSLayoutConstraint.activate([
            tooltipView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: anchorPoint.x),
            tooltipView.topAnchor.constraint(equalTo: view.topAnchor, constant: anchorPoint.y),
            tooltipView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    fileprivate func getMembers() {
    
        showSpinner()
        viewModel?.getMembers(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
    
    fileprivate func addMember() {
        
        guard
            let fieldsInput = actionDialog?.fieldsInput,
            let email = fieldsInput.first,
            let role = fieldsInput.last,
            let apiRole = AccessRole.apiRoleForValue(role) else { return }
                
        let addMemberPayload = (email, apiRole)
        actionDialog?.dismiss()
        
        showSpinner()
        viewModel?.addMember(params: addMemberPayload, then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
        
    }
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return AccessRole.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let accessRole = AccessRole(rawValue: section) else { return 0 }
        
        return viewModel?.numberOfItemsForRole(accessRole) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let accessRole = AccessRole(rawValue: indexPath.section) else {
            fatalError()
        }
        
        let cell = tableView.dequeue(cellClass: MemberTableViewCell.self, forIndexPath: indexPath)
        cell.member = viewModel?.itemAtRow(indexPath.row, withRole: accessRole)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard
            let accessRole = AccessRole(rawValue: section),
            let tooltipText = StaticData.rolesTooltipData[accessRole] else {
            fatalError()
        }
        
        let headerView = MemberRoleHeader(
            role: accessRole.groupName.pluralized(),
            tooltipText: tooltipText,
            action: { point, text in
                self.showTooltip(anchorPoint: point, text: text)
            })
        
        let numberOfItems = viewModel?.numberOfItemsForRole(accessRole)
        headerView.isSectionEmpty = numberOfItems == 0
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let lineView = UIView()
        lineView.backgroundColor = .lightGray
        return lineView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard tooltipView.isDescendant(of: view) else { return }
        tooltipView.removeFromSuperview()
    }

}
