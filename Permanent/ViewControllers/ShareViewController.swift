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
    var csrf: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareLinkViewModel()
        viewModel?.fileViewModel = sharedFile
        viewModel?.csrf = csrf
        
        linkOptionsStackView.isHidden = true
        linkOptionsView.delegate = self
        
        configureUI()
        setupTableView()
        getShareLink(option: .retrieve)
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
        tableView.register(UINib(nibName: String(describing: ArchiveTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.backgroundView = sharedFile.minArchiveVOS.isEmpty ?
            UIView.tableViewBgView(withTitle: .noSharesMessage) :
            nil
    }
    
    fileprivate func styleHeaderLabels(_ labels: [UILabel]) {
        labels.forEach {
            $0.font = Text.style3.font
            $0.textColor = .primary
        }
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
                    })
            }
        })
        
        group.enter()
        viewModel?.getRecord(then: { recordVO in
            group.leave()
        })
        
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
        return viewModel?.recordVO?.shareVOS?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveTableViewCell.self)) as? ArchiveTableViewCell else {
            return UITableViewCell()
        }
        
        guard let model = viewModel?.recordVO?.shareVOS?[indexPath.row] else { return cell }
        cell.updateCell(model: model)
        
        cell.approveAction = {
            self.viewModel?.approveButtonAction(then: { status in
                switch status {
                case .success:
                    self.view.showNotificationBanner(title: .approveShareRequest)
                    cell.hideBottomButtons(status: true)
                    
                case .error(message: let message):
                    self.showErrorAlert(message: message)
                }
            })
        }
        
        cell.denyAction = {
            self.viewModel?.denyButtonAction(then: { status in
                switch status {
                case .success:
                    self.view.showNotificationBanner(title: .denyShareRequest)
                    cell.hideBottomButtons(status: true)
                    
                case .error(message: let message):
                    self.showErrorAlert(message: message)
                }
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ShareViewController: LinkOptionsViewDelegate {
    func copyLinkAction() {
        guard let link = linkOptionsView.link else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
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
        showActionDialog(styled: .simple,
                         withTitle: "\(String.revokeLink)?",
                         positiveButtonTitle: .revoke,
                         positiveAction: {
                             self.actionDialog?.dismiss()
                             self.revokeLink()
                         },
                         overlayView: overlayView)
    }
}
