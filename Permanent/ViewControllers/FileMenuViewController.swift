//
//  FileMenuViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 24.08.2022.
//

import UIKit

class FileMenuViewController: BaseViewController<ShareLinkViewModel> {
    struct MenuItem {
        enum ItemType {
            case download
            case copy
            case move
            case delete
            case unshare
            case rename
            case publish
            case shareToPermanent
            case shareToAnotherApp
            case getLink
        }
        
        let type: ItemType
        let action: (() -> Void)?
    }
    
    var fileViewModel: FileViewModel!
    
    let scrollView: UIScrollView = UIScrollView()
    let stackView: UIStackView = UIStackView()
    
    var archivesStackView: UIStackView?
    
    var showAllArchives = false
    var shareURL: String?
    
    var menuItems: [MenuItem] = []
    
    var showsPermission: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareLinkViewModel()
        viewModel?.fileViewModel = fileViewModel
        
        view.backgroundColor = .white
        
        let itemThumbImageView = UIImageView()
        itemThumbImageView.sd_setImage(with: URL(string: fileViewModel.thumbnailURL))
        itemThumbImageView.contentMode = .scaleAspectFit
        
        let itemNameLabel = UILabel()
        itemNameLabel.text = fileViewModel.name
        itemNameLabel.textColor = .white
        itemNameLabel.font = Text.style3.font
        
        let doneButton = UIButton(type: .custom)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonPressed(_:)), for: .touchUpInside)
        
        let headerStackView = UIStackView(arrangedSubviews: [itemThumbImageView, itemNameLabel, doneButton])
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.spacing = 8
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .primary
        containerView.addSubview(headerStackView)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            headerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            headerStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            headerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            headerStackView.heightAnchor.constraint(equalToConstant: 50),
            itemThumbImageView.widthAnchor.constraint(equalToConstant: 30),
            doneButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        view.addSubview(scrollView)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: view.frame.width - 32),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: 16)
        ])

        loadSubviews()
        
        viewModel?.getShareLink(option: .retrieve, then: { shareVO, error in
            guard let shareVO = shareVO,
                shareVO.sharebyURLID != nil,
                let shareURL = shareVO.shareURL
            else {
                return
            }
            
            self.shareURL = shareURL
            
            self.loadSubviews()
        })
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didRevokeShareLinkNotifName, object: viewModel, queue: nil) { [weak self] notif in
            self?.shareURL = nil
            self?.viewModel?.shareVO = nil
            self?.loadSubviews()
        }
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didCreateShareLinkNotifName, object: viewModel, queue: nil) { [weak self] notif in
            self?.loadSubviews()
        }
    }
    
    func loadSubviews() {
        stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        
        if showsPermission {
            setupPermissionView()
        }
        
        if fileViewModel.sharedByArchive != nil {
            setupInitiatedByView()
        }
        
        if !fileViewModel.minArchiveVOS.isEmpty {
            setupSharedWithView()
        }
        
        if shareURL != nil {
            setupShareLink()
        }
        
        setupMenuView()
    }
    
    func setupPermissionView() {
        let permissionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        permissionLabel.text = "Permission:"
        permissionLabel.font = Text.style17.font
        
        let permissionValueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        permissionValueLabel.text = fileViewModel.accessRole.groupName
        permissionValueLabel.font = Text.style8.font
        
        let subStackView = UIStackView(arrangedSubviews: [permissionLabel, permissionValueLabel])
        subStackView.axis = .vertical
        subStackView.spacing = 8
        subStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subStackView.widthAnchor.constraint(equalToConstant: stackView.frame.width)
        ])
        stackView.addArrangedSubview(subStackView)
    }
    
    func setupInitiatedByView() {
        let initiatedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        initiatedLabel.text = "Initiated by:"
        initiatedLabel.font = Text.style17.font
        stackView.addArrangedSubview(initiatedLabel)
        
        let imageView = UIImageView(image: UIImage.profile)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        if let url = URL(string: fileViewModel.sharedByArchive?.thumbnail) {
            imageView.sd_setImage(with: url)
        }
        
        let initiatedValueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        initiatedValueLabel.text = "The \(fileViewModel.sharedByArchive?.name ?? "") Archive"
        initiatedValueLabel.font = Text.style8.font
        
        let itemStackView = UIStackView(arrangedSubviews: [imageView, initiatedValueLabel])
        itemStackView.axis = .horizontal
        itemStackView.spacing = 8
        itemStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemStackView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let subStackView = UIStackView(arrangedSubviews: [initiatedLabel, itemStackView])
        subStackView.axis = .vertical
        subStackView.spacing = 8
        subStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subStackView.widthAnchor.constraint(equalToConstant: stackView.frame.width)
        ])
        stackView.addArrangedSubview(subStackView)
    }
    
    func setupSharedWithView() {
        reloadArchivesStackView()
        if stackView.arrangedSubviews.contains(archivesStackView!) == false {
            stackView.addArrangedSubview(archivesStackView!)
        }
        
        if fileViewModel.minArchiveVOS.count > 2 && showAllArchives == false {
            let button = UIButton(type: .custom)
            button.setTitle("Shared with \(fileViewModel.minArchiveVOS.count - 2) more archives", for: .normal)
            button.setTitleColor(.primary, for: .normal)
            button.setFont(Text.style13.font)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.primary.cgColor
            button.addTarget(self, action: #selector(showAllArchivesButtonPressed(_:)), for: .touchUpInside)
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
            stackView.addArrangedSubview(button)
        }
    }
    
    func reloadArchivesStackView() {
        var subviews: [UIView] = []
        archivesStackView?.arrangedSubviews.forEach({ view in
            view.removeFromSuperview()
        })
        
        let sharedWithLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        sharedWithLabel.text = "Shared with:"
        sharedWithLabel.font = Text.style17.font
        subviews.append(sharedWithLabel)
        
        let maxArchivesShown = showAllArchives ? fileViewModel.minArchiveVOS.count : min(fileViewModel.minArchiveVOS.count, 2)
        for (idx, archive) in fileViewModel.minArchiveVOS[0 ..< maxArchivesShown].enumerated() {
            let archiveStackView = archiveStackView(withArchiveName: "The \(archive.name) Archive", imagePath: archive.thumbnail, tag: idx + 1)
            subviews.append(archiveStackView)
        }
        
        if archivesStackView == nil {
            let subStackView = UIStackView(arrangedSubviews: subviews)
            subStackView.axis = .vertical
            subStackView.spacing = 8
            subStackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                subStackView.widthAnchor.constraint(equalToConstant: stackView.frame.width)
            ])
            archivesStackView = subStackView
        } else {
            subviews.forEach { view in
                archivesStackView?.addArrangedSubview(view)
            }
        }
    }
    
    func archiveStackView(withArchiveName name: String, imagePath: String, tag: Int) -> UIView {
        let imageView = UIImageView(image: UIImage.profile)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        if let url = URL(string: imagePath) {
            imageView.sd_setImage(with: url)
        }
        
        let archiveNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        archiveNameLabel.text = name
        archiveNameLabel.font = Text.style7.font
        
        let removeButton = UIButton(type: .custom)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setImage(UIImage.close.templated, for: .normal)
        removeButton.imageView?.tintColor = .doveGray
        removeButton.imageView?.contentMode = .scaleAspectFit
        removeButton.tag = tag
        removeButton.addTarget(self, action: #selector(removeArchive(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            removeButton.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        let archiveButton = UIButton(type: .custom)
        archiveButton.tag = tag
        archiveButton.translatesAutoresizingMaskIntoConstraints = false
        archiveButton.addTarget(self, action: #selector(editArchive(_:)), for: .touchUpInside)
        
        let archiveStackView = UIStackView(arrangedSubviews: [imageView, archiveNameLabel, removeButton])
        archiveStackView.axis = .horizontal
        archiveStackView.spacing = 8
        archiveStackView.translatesAutoresizingMaskIntoConstraints = false
        archiveStackView.addSubview(archiveButton)
        NSLayoutConstraint.activate([
            archiveStackView.heightAnchor.constraint(equalToConstant: 30),
            archiveButton.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 0),
            archiveButton.trailingAnchor.constraint(equalTo: archiveNameLabel.trailingAnchor, constant: 0),
            archiveButton.topAnchor.constraint(equalTo: archiveStackView.topAnchor, constant: 0),
            archiveButton.bottomAnchor.constraint(equalTo: archiveStackView.bottomAnchor, constant: 0)
        ])
        
        return archiveStackView
    }
    
    func setupShareLink() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.primary.cgColor
        
        let imageView = UIImageView(image: UIImage(named: "Get Link")?.templated ?? .placeholder.templated)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .primary
        imageView.contentMode = .scaleAspectFit
        containerView.addSubview(imageView)
        
        let linkLabel = UILabel()
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        linkLabel.text = shareURL
        linkLabel.font = Text.style13.font
        linkLabel.textColor = .primary
        containerView.addSubview(linkLabel)
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(shareLinkButtonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: linkLabel.leadingAnchor, constant: -8),
            linkLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            linkLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            containerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        stackView.addArrangedSubview(containerView)
    }
    
    func setupMenuView() {
        let file: FileViewModel! = fileViewModel
        
        if file.permissions.contains(.read) && file.type.isFolder == false, let menuIndex = menuItems.firstIndex(where: { $0.type == .download }) {
            stackView.addArrangedSubview(menuItem(withName: "Download to device".localized(), iconName: "Download-1", tag: menuIndex + 1))
        }
        if file.permissions.contains(.create), let menuIndex = menuItems.firstIndex(where: { $0.type == .copy }) {
            stackView.addArrangedSubview(menuItem(withName: "Copy to another location".localized(), iconName: "Copy", tag: menuIndex + 1))
        }
        if file.permissions.contains(.move), let menuIndex = menuItems.firstIndex(where: { $0.type == .move }) {
            stackView.addArrangedSubview(menuItem(withName: "Move to another location".localized(), iconName: "Move", tag: menuIndex + 1))
        }
        if file.permissions.contains(.delete), let menuIndex = menuItems.firstIndex(where: { $0.type == .delete }) {
            stackView.addArrangedSubview(menuItem(withName: "Delete".localized(), iconName: "Delete-1", tag: menuIndex + 1))
        }
        if let menuIndex = menuItems.firstIndex(where: { $0.type == .unshare }) {
            stackView.addArrangedSubview(menuItem(withName: "Unshare".localized(), iconName: "Delete-1", tag: menuIndex + 1))
        }
        if file.permissions.contains(.edit), let menuIndex = menuItems.firstIndex(where: { $0.type == .rename }) {
            stackView.addArrangedSubview(menuItem(withName: "Rename".localized(), iconName: "Rename", tag: menuIndex + 1))
        }
        if file.permissions.contains(.publish), let menuIndex = menuItems.firstIndex(where: { $0.type == .publish }) {
            stackView.addArrangedSubview(menuItem(withName: "Publish".localized(), iconName: "Public Files", tag: menuIndex + 1))
        }
        if let menuIndex = menuItems.firstIndex(where: { $0.type == .getLink }) {
            stackView.addArrangedSubview(menuItem(withName: "Get Link".localized(), iconName: "Get Link", tag: menuIndex + 1))
        }
        if file.permissions.contains(.share) {
            if file.permissions.contains(.ownership) && menuItems.firstIndex(where: { $0.type == .shareToPermanent }) != nil {
                stackView.addArrangedSubview(menuItem(withName: "Share management".localized(), iconName: "Link Settings", tag: -101))
            }
            
            if file.type.isFolder == false, let menuIndex = menuItems.firstIndex(where: { $0.type == .shareToAnotherApp }) {
                stackView.addArrangedSubview(menuItem(withName: "Share to Another App".localized(), iconName: "Share Other", tag: menuIndex + 1))
            }
        }
    }
    
    func menuItem(withName name: String, iconName: String, tag: Int) -> UIView {
        let imageView = UIImageView(image: UIImage(named: iconName) ?? .placeholder)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        nameLabel.text = name
        nameLabel.font = Text.style7.font
        
        let itemStackView = UIStackView(arrangedSubviews: [imageView, nameLabel])
        itemStackView.axis = .horizontal
        itemStackView.spacing = 8
        itemStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.accessibilityIdentifier = name
        containerView.addSubview(itemStackView)
        
        let button = UIButton(type: .custom)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints    = false
        button.addTarget(self, action: #selector(menuButtonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        
        NSLayoutConstraint.activate([
            itemStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            itemStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            itemStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            itemStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            itemStackView.heightAnchor.constraint(equalToConstant: 30),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
        
        return containerView
    }
    
    @objc func showAllArchivesButtonPressed(_ sender: Any) {
        showAllArchives = true
        
        loadSubviews()
    }
    
    @objc func menuButtonPressed(_ sender: UIButton) {
        switch sender.tag {
        case -100:
            createLinkAction()
            
        case -101:
            manageLinkAction()
            
        default:
            dismiss(animated: true) {
                let tag = sender.tag
                let action = self.menuItems[tag - 1].action
                action?()
            }
        }
    }
    
    @objc func shareLinkButtonPressed(_ sender: UIView) {
        guard let link = shareURL else {
            return
        }
    
        let activityViewController = UIActivityViewController(activityItems: [URL(string: link) as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func removeArchive(_ sender: UIButton) {
        let archive = fileViewModel.minArchiveVOS[sender.tag - 1]
        let description = "Are you sure you want to remove The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archive.name)
        
        showActionDialog(
            styled: .simpleWithDescription,
            withTitle: description,
            description: "",
            positiveButtonTitle: "Remove".localized(),
            positiveAction: { [weak self] in
                self?.actionDialog?.dismiss()
                self?.actionDialog = nil
                
                self?.showSpinner()
                self?.viewModel?.denyButtonAction(minArchiveVO: archive, then: { status in
                    self?.hideSpinner()
                    
                    if status == .success {
                        self?.view.showNotificationBanner(title: "Archive successfully removed".localized())
                        self?.fileViewModel.minArchiveVOS.removeAll(where: { $0.archiveID == archive.archiveID })
                    } else {
                        self?.view.showNotificationBanner(title: .errorMessage, backgroundColor: .brightRed, textColor: .white)
                    }
                    
                    self?.loadSubviews()
                })
            },
            cancelButtonTitle: "Cancel".localized(),
            positiveButtonColor: .brightRed,
            cancelButtonColor: .primary,
            overlayView: nil
        )
    }
    
    @objc func editArchive(_ sender: UIButton) {
        let archiveVO = fileViewModel.minArchiveVOS[sender.tag - 1]
        
        let accessRoles = AccessRole.allCases
            .filter { $0 != .owner && $0 != .manager }
            .map { $0.groupName }
        
        self.showActionDialog(
            styled: .dropdownWithDescription,
            withTitle: "The \(archiveVO.name) Archive",
            placeholders: [AccessRole.roleForValue(archiveVO.accessRole ?? "").groupName],
            dropdownValues: accessRoles,
            positiveButtonTitle: "Update".localized(),
            positiveAction: { [weak self] in
                if let fieldsInput = self?.actionDialog?.fieldsInput,
                let roleValue = fieldsInput.first {
                    self?.showSpinner()
                    
                    let accessRole = AccessRole.roleForValue(AccessRole.apiRoleForValue(roleValue))
                    self?.viewModel?.approveButtonAction(minArchiveVO: archiveVO, accessRole: accessRole, then: { status in
                        self?.hideSpinner()
                        
                        switch status {
                        case .success:
                            self?.view.showNotificationBanner(title: "Access role was successfully changed".localized())
                            
                        case .error(let errorMessage):
                            self?.view.showNotificationBanner(title: errorMessage ?? .errorMessage, backgroundColor: .brightRed, textColor: .white)
                        }
                        
                        self?.fileViewModel.minArchiveVOS[sender.tag - 1].accessRole = AccessRole.apiRoleForValue(accessRole.groupName)
                    })
                }
                
                self?.actionDialog?.dismiss()
                self?.actionDialog = nil
            },
            overlayView: nil
        )
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func manageLinkAction() {
        guard
            let manageLinkVC = UIViewController.create(withIdentifier: .share, from: .share) as? ShareViewController
        else {
            return
        }
        
        manageLinkVC.viewModel = viewModel
        present(manageLinkVC, animated: true)
    }
    
    func createLinkAction() {
        showSpinner()
        viewModel?.getShareLink(option: .create, then: { shareVO, error in
            self.hideSpinner()
            
            guard let shareVO = shareVO,
                shareVO.sharebyURLID != nil,
                let shareURL = shareVO.shareURL
            else {
                return
            }
            
            self.shareURL = shareURL
            
            self.loadSubviews()
        })
    }
}
