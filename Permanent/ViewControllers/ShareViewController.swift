//
//  ShareViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 03.12.2020.
//

import UIKit

class ShareViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet var filenameLabel: UILabel!
    @IBOutlet var createLinkButton: RoundedButton!
    @IBOutlet var linkOptionsView: LinkOptionsView!
    @IBOutlet var linkOptionsStackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var sharingWithLabel: UILabel!
    
    private let overlayView = UIView()
    
    var sharedFile: FileViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareLinkViewModel()
        viewModel?.fileViewModel = sharedFile
        
        linkOptionsStackView.isHidden = true
        linkOptionsView.delegate = self
        
        configureUI()
        setupTableView()
        getShareLink(option: .retrieve)
        
        tableView.estimatedRowHeight = 40
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    fileprivate func configureUI() {
        styleNavBar()
        navigationItem.title = .share
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonPressed(_:)))
        
        createLinkButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        createLinkButton.bgColor = .primary
        createLinkButton.setTitle(.getShareLink, for: [])
        
        styleHeaderLabels([filenameLabel, titleLabel, sharingWithLabel])
        
        filenameLabel.text = sharedFile.name
        titleLabel.text = .shareLink
        descriptionLabel.text = .shareDescription
        descriptionLabel.font = Text.style8.font
        descriptionLabel.textColor = .textPrimary
        
        linkOptionsView.configureButtons(withData: StaticData.shareLinkButtonsConfig)
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
    }
    
    fileprivate func setupTableView() {
        tableView.register(
            UINib(nibName: String(describing: ArchiveTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ArchiveTableViewCell.self)
        )
        tableView.tableFooterView = UIView()
        tableView.backgroundView = sharedFile.minArchiveVOS.isEmpty ? UIView.tableViewBgView(withTitle: .noSharesMessage) : nil
        tableView.allowsSelection = false
    }
    
    fileprivate func styleHeaderLabels(_ labels: [UILabel]) {
        labels.forEach {
            $0.font = Text.style3.font
            $0.textColor = .primary
        }
    }
    
    func editArchive(shareVO: ShareVOData) {
        guard let archiveVO = shareVO.archiveVO else { return }
        
        let accessRoles = AccessRole.allCases
            .filter { $0 != .owner && $0 != .manager }
            .map { $0.groupName }
        
        self.showActionDialog(
            styled: .dropdownWithDescription,
            withTitle: "The \(archiveVO.fullName ?? "") Archive",
            placeholders: [AccessRole.roleForValue(shareVO.accessRole ?? "").groupName],
            dropdownValues: accessRoles,
            positiveButtonTitle: "Update".localized(),
            positiveAction: { [weak self] in
                if let fieldsInput = self?.actionDialog?.fieldsInput,
                let roleValue = fieldsInput.first {
                    self?.showSpinner()
                    
                    let accessRole = AccessRole.roleForValue(AccessRole.apiRoleForValue(roleValue))
                    self?.viewModel?.approveButtonAction(shareVO: shareVO, accessRole: accessRole, then: { status in
                        self?.hideSpinner()
                        
                        switch status {
                        case .success:
                            self?.view.showNotificationBanner(title: "Access role was successfully changed".localized())
                            
                        case .error(let errorMessage):
                            self?.view.showNotificationBanner(title: errorMessage ?? .errorMessage, backgroundColor: .brightRed, textColor: .white)
                        }
                        
                        self?.getShareLink(option: .retrieve)
                    })
                }
                
                self?.actionDialog?.dismiss()
                self?.actionDialog = nil
            },
            overlayView: self.overlayView
        )
    }

    @IBAction func createLinkAction(_ sender: UIButton) {
        getShareLink(option: .create)
    }
    
    @objc func closeButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Network Requests
    
    fileprivate func getShareLink(option: ShareLinkOption) {
        showSpinner()
        
        let group = DispatchGroup()
        
        group.enter()
        viewModel?.getShareLink(option: option, then: { shareVO, error in
            group.leave()
            
            guard error == nil else {
                return
            }
            
            guard
                let shareVO = shareVO,
                shareVO.sharebyURLID != nil,
                let shareURL = shareVO.shareURL
            else {
                return
            }
            
            self.linkOptionsView.link = shareURL
            
            DispatchQueue.main.async {
                self.createLinkButton.isHidden = true
                UIView.animate(
                    animations: {
                    self.linkOptionsStackView.isHidden = false
                    }
                )
            }
        })
        
        if sharedFile.type.isFolder {
            group.enter()
            viewModel?.getFolder(then: { folderVO in
                group.leave()
            })
        } else {
            group.enter()
            viewModel?.getRecord(then: { recordVO in
                if recordVO == nil {
                    self.viewModel?.getFolder(then: { folderVO in
                        group.leave()
                    })
                } else {
                    group.leave()
                }
            })
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.hideSpinner()
            self.tableView.reloadData()
        }
    }
    
    fileprivate func revokeLink() {
        showSpinner()
        
        viewModel?.revokeLink(then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.linkOptionsStackView.isHidden = true
                    UIView.animate(animations: {
                        self.createLinkButton.isHidden = false
                    })
                }
               
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
}

extension ShareViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.shareVOS?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveTableViewCell.self)) as? ArchiveTableViewCell else {
            return UITableViewCell()
        }
        
        guard let model = viewModel?.shareVOS?[indexPath.row] else { return cell }
        cell.updateCell(model: model)
        
        cell.approveAction = { [weak self] in
            self?.viewModel?.approveButtonAction(shareVO: model, then: { status in
                switch status {
                case .success:
                    self?.view.showNotificationBanner(title: .approveShareRequest)
                    cell.hideBottomButtons(status: true)
                    
                    self?.getShareLink(option: .retrieve)
                    tableView.reloadData()
                    
                case .error(message: let message):
                    self?.showErrorAlert(message: message)
                }
            })
        }
         
        cell.denyAction = { [weak self] in
            self?.viewModel?.denyButtonAction(shareVO: model, then: { status in
                switch status {
                case .success:
                    self?.view.showNotificationBanner(title: .denyShareRequest)
                    cell.hideBottomButtons(status: true)
                    
                    self?.getShareLink(option: .retrieve)
                    tableView.reloadData()
                    
                case .error(message: let message):
                    self?.showErrorAlert(message: message)
                }
            })
        }
        
        cell.rightButtonTapAction = { [weak self] cell in
            var actions = [
                PRMNTAction(title: "Edit".localized(), color: .primary, handler: { action in
                    self?.editArchive(shareVO: model)
                })
            ]
            
            actions.insert(PRMNTAction(title: "Remove".localized(), color: .destructive, handler: { [weak self] action in
                print("remove")
                let description = "Are you sure you want to remove The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: model.archiveVO?.fullName ?? "")
                
                self?.showActionDialog(
                    styled: .simpleWithDescription,
                    withTitle: description,
                    description: "",
                    positiveButtonTitle: "Remove".localized(),
                    positiveAction: { [weak self] in
                        self?.actionDialog?.dismiss()
                        self?.actionDialog = nil
                        
                        self?.showSpinner()
                        self?.viewModel?.denyButtonAction(shareVO: model, then: { status in
                            self?.hideSpinner()
                            if status == .success {
                                self?.view.showNotificationBanner(title: "Archive successfully removed".localized())
                            } else {
                                self?.view.showNotificationBanner(title: .errorMessage, backgroundColor: .brightRed, textColor: .white)
                            }
                            self?.getShareLink(option: .retrieve)
                        })
                    },
                    cancelButtonTitle: "Cancel".localized(),
                    positiveButtonColor: .brightRed,
                    cancelButtonColor: .primary,
                    overlayView: self?.overlayView
                )
            }), at: 0)
            
            let actionSheet = PRMNTActionSheetViewController(actions: actions)
            self?.present(actionSheet, animated: true)
        }
        
        return cell
    }
}

extension ShareViewController: LinkOptionsViewDelegate {
    func copyLinkAction() {
        var emailSubject = "<ACCOUNTNAME> wants to share an item from their Permanent Archive with you".localized()
        var emailBody = "<ACCOUNTNAME> wants to share an item from their Permanent Archive with you.\n <LINK>".localized()
        
        guard let link = linkOptionsView.link,
            let name = viewModel?.getAccountName() else {
            return
        }
        emailSubject = emailSubject.replacingOccurrences(of: "<ACCOUNTNAME>", with: "\(name)")
        emailBody = emailBody.replacingOccurrences(of: "<ACCOUNTNAME>", with: "\(name)")
        emailBody = emailBody.replacingOccurrences(of: "<LINK>", with: "\(link)")
    
        let activityViewController = UIActivityViewController(activityItems: [emailBody], applicationActivities: nil)
        activityViewController.setValue(emailSubject, forKey: "Subject")
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    func manageLinkAction() {
        guard
            let manageLinkVC = UIViewController.create(withIdentifier: .manageLink, from: .share) as? ManageLinkViewController
        else {
            return
        }
        
        manageLinkVC.shareViewModel = viewModel
        navigationController?.display(viewController: manageLinkVC, modally: true)
    }
    
    func revokeLinkAction() {
        showActionDialog(
            styled: .simple,
            withTitle: "\(String.revokeLink)?",
            positiveButtonTitle: .revoke,
            positiveAction: {
                self.actionDialog?.dismiss()
                self.revokeLink()
            },
            overlayView: overlayView
        )
    }
}
