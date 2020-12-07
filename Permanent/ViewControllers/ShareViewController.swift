//  
//  ShareViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 03.12.2020.
//

import UIKit

class ShareViewController: UIViewController {
    @IBOutlet var filenameLabel: UILabel!
    @IBOutlet var createLinkButton: RoundedButton!
    @IBOutlet var linkOptionsView: LinkOptionsView!
    @IBOutlet var linkOptionsStackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var sharingWithLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        linkOptionsStackView.isHidden = true
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .settings, style: .plain, target: self, action: #selector(toggleView))
        
        
        configureUI()
        setupTableView()
    }
    
    fileprivate func configureUI() {
        
        navigationItem.title = "Share"
        
        createLinkButton.layer.cornerRadius = Constants.Design.actionButtonRadius
        createLinkButton.bgColor = .primary
        createLinkButton.setTitle(.getShareLink, for: [])
        
        styleHeaderLabels([filenameLabel, titleLabel, sharingWithLabel])
        
        filenameLabel.text = "Around the world" // TODO
        titleLabel.text = .shareLink
        descriptionLabel.text = .shareDescription
        descriptionLabel.font = Text.style8.font
        descriptionLabel.textColor = .textPrimary
        
        linkOptionsView.link = "https://www.permanent.org/p/archive/00sm-00"
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
    
    
    @objc // TEST. Will be deleted.
    func toggleView() {
        linkOptionsStackView.isHidden.toggle()
        createLinkButton.isHidden.toggle()
        
    }
    @IBAction func createLinkAction(_ sender: UIButton) {
        createLinkButton.isHidden = true
        linkOptionsStackView.isHidden = false
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
