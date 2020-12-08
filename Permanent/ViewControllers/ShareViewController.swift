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
        getShareLink()
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .share
        
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
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: ArchiveTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: ArchiveTableViewCell.self))
        tableView.tableFooterView = UIView()
    }
    
    fileprivate func styleHeaderLabels(_ labels: [UILabel]) {
        labels.forEach {
            $0.font = Text.style3.font
            $0.textColor = .primary
        }
    }

    @IBAction func createLinkAction(_ sender: UIButton) {
        self.createLinkButton.isHidden = true
        UIView.animate(
            animations: {
            self.linkOptionsStackView.isHidden = false
        })
    }
    
    // MARK: - Network Requests
    
    fileprivate func getShareLink() {
        viewModel?.getShareLink(then: { shareVO, error in
            guard error == nil else {
                self.showToast(message: "Share by URL id is null")
                return
            }
            
            guard
                let shareVO = shareVO?.shareByURLVO,
                shareVO.sharebyURLID != nil,
                let shareURL = shareVO.shareURL else {
                
                self.showToast(message: "Share by URL id is null")
                return
            }
            
            self.linkOptionsView.link = shareURL
            
            // TODO:
            self.createLinkButton.isHidden = true
            self.linkOptionsStackView.isHidden = false
        })
    }
}

extension ShareViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ArchiveTableViewCell.self)) else {
            fatalError()
        }
        return cell
    }
}

extension ShareViewController: LinkOptionsViewDelegate {
    func copyLink() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = linkOptionsView.link
        view.showNotificationBanner(height: Constants.Design.bannerHeight, title: .linkCopied)
    }
    
    func revokeLink() {
        self.linkOptionsStackView.isHidden = true
        UIView.animate(animations: {
            self.createLinkButton.isHidden = false
        })
    }
}
