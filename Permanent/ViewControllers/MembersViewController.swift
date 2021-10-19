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
    
    var parametersActionDialog: AddMemberParams = (nil,"","")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = MembersViewModel()
        
        configureUI()
        setupTableView()
        
        if checkSavedNotification() == false {
            getMembers()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    fileprivate func configureUI() {
        styleNavBar()
        
        navigationItem.title = String.member.pluralized()
        view.backgroundColor = .backgroundPrimary
        addMembersButton.configureActionButtonUI(title: String.addMember.pluralized())
        
        addMembersButton.isHidden = viewModel!.archivePermissions.contains(.archiveShare) == false
        
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
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 40
    }
    
    func checkSavedNotification() -> Bool {
        var hasSavedNotification = false
        
        if let requestPAAccess: PARequestNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.requestPAAccess) {
            hasSavedNotification = true
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestPAAccess)
            
            let currentArchive: ArchiveVOData? = viewModel?.currentArchive
            if currentArchive?.archiveNbr != requestPAAccess.toArchiveNbr {
                let action = { [weak self] in
                    self?.actionDialog?.dismiss()
                    
                    self?.viewModel?.changeArchive(withArchiveId: requestPAAccess.toArchiveId, archiveNbr: requestPAAccess.toArchiveNbr, completion: { success in
                        self?.getMembers()
                    })
                    
                    self?.actionDialog = nil
                }
                
                let title = "Switch to The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: requestPAAccess.toArchiveName)
                let description = "In order to access this content you need to switch to The <ARCHIVE_NAME> Archive.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: requestPAAccess.toArchiveName)
                showActionDialog(styled: .simpleWithDescription,
                                 withTitle: title,
                                 description: description,
                                 positiveButtonTitle: "Switch".localized(),
                                 positiveAction: action,
                                 cancelButtonTitle: "Cancel".localized(),
                                 overlayView: overlayView)
            } else {
                getMembers()
            }
        }
        
        return hasSavedNotification
    }
    
    @IBAction func addMembersAction(_ sender: UIButton) {
        self.showActionDialog(
            styled: .inputWithDropdown,
            withTitle: .addMember,
            placeholders: [.memberEmail, .accessLevel],
            dropdownValues: StaticData.allAccessRoles,
            positiveButtonTitle: .save,
            positiveAction: {
                if let currentEmail = self.actionDialog?.fieldsInput.first {
                    if currentEmail.isValidEmail {
                        if let currentRole = self.actionDialog?.fieldsInput.last {
                            if currentRole == .owner {
                                self.transferOwnership(withOperation: .transferOwnership)
                            } else if currentRole == .accessLevel {
                                self.showEmailWarning("Please choose an access level from the list".localized())
                            } else {
                                self.modifyMember(withOperation: .add)
                            }
                        }
                    } else {
                        self.showEmailWarning(.emailIsNotValid)
                    }
                }
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
    
    fileprivate func modifyMember(_ member: Account? = nil, withOperation operation: MemberOperation) {
        guard let parameters = getModifyMemberParams(member: member, operation: operation) else { return }
        
        actionDialog?.dismiss()
        
        showSpinner()
        viewModel?.modifyMember(operation, params: parameters, then: { status in
            switch status {
            case .success:
                self.getMembers()
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.view.showNotificationBanner(title: message ?? .errorMessage, backgroundColor: .deepRed, textColor: .white)
                }
            }
        })
    }
    
    fileprivate func getModifyMemberParams(member: Account?, operation: MemberOperation) -> AddMemberParams? {
        switch operation {
        case .add:
            guard
                let fieldsInput = actionDialog?.fieldsInput,
                let email = fieldsInput.first,
                let role = fieldsInput.last,
                let apiRole = AccessRole.apiRoleForValue(role) else { return nil }
            
            return (nil, email, apiRole)
            
        case .edit:
            guard
                let account = member,
                let fieldsInput = actionDialog?.fieldsInput,
                let role = fieldsInput.first,
                let apiRole = AccessRole.apiRoleForValue(role) else { return nil }
            
            return (account.accountId, account.email, apiRole)
            
        case .remove:
            guard
                let account = member,
                let apiRole = AccessRole.apiRoleForValue(account.accessRole.groupName) else { return nil }
            
            return (nil, account.email, apiRole)
            
        case .transferOwnership:
            var email: String = ""
            
            if let account = member {
                email = account.email
            } else {
                guard
                    let fieldsInput = actionDialog?.fieldsInput.first else { return nil }
                email = fieldsInput
            }
            
            return (nil, email, "")
        }
    }
    
    fileprivate func didTapDelete(forAccount account: Account) {
        self.showActionDialog(styled: .simple,
                              withTitle: String.init(format: .removeMember, account.name),
                              positiveButtonTitle: .remove,
                              positiveAction: { [weak self] in
                                self?.modifyMember(account, withOperation: .remove)
                              },
                              overlayView: self.overlayView
        )
    }
    
    fileprivate func didTapEdit(forAccount account: Account) {
        self.showActionDialog(styled: .dropdownWithDescription,
                            withTitle: account.name,
                            description: account.email,
                            placeholders: [.accessLevel],
                            prefilledValues: [account.accessRole.groupName],
                            dropdownValues: StaticData.allAccessRoles,
                            positiveButtonTitle: .save,
                            positiveAction: {
                                if let newMemberRole = self.actionDialog?.fieldsInput.last,
                                   newMemberRole == .owner {
                                        self.transferOwnership(account, withOperation: .transferOwnership)
                                    } else {
                                        if account.accessRole != .owner {
                                            self.modifyMember(account, withOperation: .edit)
                                        } else {
                                            self.actionDialog?.dismiss()
                                            self.view.showNotificationBanner(height: 60, title: "You cannot change the access level of the Permanent Archive owner".localized(), backgroundColor: .deepRed, textColor: .white, animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
                                        }
                                    }
                            },
                            overlayView: self.overlayView
        )
    }
    
    fileprivate func transferOwnership(_ member: Account? = nil, withOperation operation: MemberOperation) {
        if let parameters = getModifyMemberParams(member: member, operation: operation) {
            parametersActionDialog = parameters
        } else { return }
        
        actionDialog?.dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActionDialog(styled: .simpleWithDescription,
                                  withTitle: .transferOwnership,
                                  description: String.transferOwnershipInfo,
                                  placeholders: [.accessLevel],
                                  positiveButtonTitle: String.transferButtonText,
                                  positiveAction: { [self] in
                                    actionDialog?.dismiss()
                                    actionDialog = nil
                                    showSpinner()
                
                                    viewModel?.transferOwnership(email: self.parametersActionDialog.email , then: { status in
                                        hideSpinner()
                                        switch status {
                                        case .success:
                                            self.view.showNotificationBanner(height: Constants.Design.bannerHeight,title: "Ownership transfer request sent".localized())
                                            self.getMembers()
                                        case .error(message: let message):
                                            self.view.showNotificationBanner(title: message ?? .errorMessage, backgroundColor: .deepRed, textColor: .white, animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
                                        }
                                    })
                                  },
                                  overlayView: self.overlayView
            )}
    }
    
    func showEmailWarning(_ message: String) {
        let alert = UIAlertController(title: .error, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: {_ in
            self.actionDialog?.dismiss()
        }))
        alert.addAction(UIAlertAction(title: .retry, style: .default, handler: {_ in
        }))
        
        self.present(alert, animated: true)
    }
    
    func showFileActionSheet(forAccount account: Account, atIndexPath indexPath: IndexPath) {
        var actions: [PRMNTAction] = []
        
        actions.append(PRMNTAction(title: "Remove".localized(), color: .brightRed, handler: { [self] action in
            modifyMember(account, withOperation: .remove)
        }))
        
        actions.append(PRMNTAction(title: "Edit".localized(), color: .primary, handler: { [self] action in
            didTapEdit(forAccount: account)
        }))
    
        let actionSheet = PRMNTActionSheetViewController(title: account.email, actions: actions)
        present(actionSheet, animated: true, completion: nil)
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
        
        let member = viewModel?.itemAtRow(indexPath.row, withRole: accessRole)
        cell.member = member
        
        let hasEditPermission = viewModel?.archivePermissions.contains(.archiveShare) ?? false
        cell.editButton.isHidden = !((hasEditPermission && member?.accessRole != .owner)||(member?.accessRole == .owner && member?.status == .pending))
        
        cell.editButtonAction = { [weak self] cell in
            guard let viewModel = self?.viewModel,
                let accessRole = AccessRole(rawValue: indexPath.section),
                let account = viewModel.itemAtRow(indexPath.row, withRole: accessRole) else {
                return
            }
            
            self?.showFileActionSheet(forAccount:account, atIndexPath: indexPath)
        }
        
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
        
        let sectionName = accessRole != .owner ?
            accessRole.groupName.pluralized() :
            accessRole.groupName
        
        let headerView = MemberRoleHeader(
            role: sectionName,
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard
            let viewModel = viewModel,
            let accessRole = AccessRole(rawValue: indexPath.section),
            let account = viewModel.itemAtRow(indexPath.row, withRole: accessRole) else {
            return nil
        }
        
        let deleteAction = UIContextualAction.make(
            withImage: .removeAction,
            backgroundColor: .destructive,
            handler: { _, _, completion in
                self.didTapDelete(forAccount: account)
                completion(true)
            }
        )
        
        let editAction = UIContextualAction.make(
            withImage: .editAction,
            backgroundColor: .primary,
            handler: { _, _, completion in
                self.didTapEdit(forAccount: account)
                completion(true)
            }
        )
        
        return UISwipeActionsConfiguration(actions: [
            editAction,
            deleteAction
        ])
    }

}
