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
    
    var selectedItemCount: Int?

    let overlayView = UIView(frame: .zero)
    var contentViewBottomConstraint: NSLayoutConstraint!
    let contentView = UIView(frame: .zero)

    var panGestureRecognizer = UIPanGestureRecognizer()
    var scrollViewHeightAnchorConstraint: NSLayoutConstraint!

    let navigationBarHeight: CGFloat = 150
    private var previousYTranslation: CGFloat = 0
    private var isExpanded: Bool = false
    
    private var initialCenter: CGPoint = .zero
    private var scrollViewInitialHeight: CGFloat = .zero
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareLinkViewModel(fileViewModel: fileViewModel)
        //viewModel?.fileViewModel = fileViewModel
        
        view.backgroundColor = .clear
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .darkGray.withAlphaComponent(0.5)
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:))))
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    
        let itemThumbImageView = UIImageView()
        itemThumbImageView.sd_setImage(with: URL(string: fileViewModel.thumbnailURL))
        itemThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        itemThumbImageView.contentMode = .scaleAspectFill
        itemThumbImageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            itemThumbImageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        let itemNameLabel = UILabel()
        if let selectedItemCount = selectedItemCount, selectedItemCount > 1 {
            itemNameLabel.text = "<COUNT> Items selected".localized().replacingOccurrences(of: "<COUNT>", with: "\(selectedItemCount)")
        } else {
            itemNameLabel.text = fileViewModel.name
        }

        itemNameLabel.textColor = .white
        itemNameLabel.font = TextFontStyle.style3.font
        
        let doneButton = UIButton(type: .custom)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonPressed(_:)), for: .touchUpInside)
        
        let handleBar = UIView()
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        handleBar.alpha = 0.5
        handleBar.backgroundColor = .white
        handleBar.layer.cornerRadius = 2
        
        let headerStackView = UIStackView(arrangedSubviews: [itemThumbImageView, itemNameLabel, doneButton])
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.spacing = 8
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .primary
        containerView.addSubview(headerStackView)
        containerView.addSubview(handleBar)
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        contentView.addSubview(containerView)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.isEnabled = true
        panGestureRecognizer.delegate = self
        contentView.addGestureRecognizer(panGestureRecognizer)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            handleBar.bottomAnchor.constraint(equalTo: headerStackView.topAnchor, constant: -8),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 0),
            handleBar.heightAnchor.constraint(equalToConstant: 4),
            handleBar.widthAnchor.constraint(equalToConstant: 32),
            headerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            headerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            headerStackView.heightAnchor.constraint(equalToConstant: 30),
            doneButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        contentView.addSubview(scrollView)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: view.frame.width - 48),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: 16)
        ])

        loadSubviews()
        view.layoutIfNeeded()
        
        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: scrollView.contentSize.height)
        if scrollView.contentSize.height < view.frame.height / 3 {
            scrollViewHeightAnchorConstraint = scrollView.heightAnchor.constraint(equalToConstant: scrollView.contentSize.height + 70)
        } else {
            scrollViewHeightAnchorConstraint = scrollView.heightAnchor.constraint(equalToConstant: view.frame.height / 3 + 70)
        }
        scrollViewInitialHeight = scrollViewHeightAnchorConstraint.constant
        
        NSLayoutConstraint.activate([
            contentViewBottomConstraint,
            scrollViewHeightAnchorConstraint
        ])
        
        view.layoutIfNeeded()
        if selectedItemCount == nil {
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
        }
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didRevokeShareLinkNotifName, object: viewModel, queue: nil) { [weak self] notif in
            self?.shareURL = nil
            self?.viewModel?.shareVO = nil
            self?.loadSubviews()
            
            if let scrollViewContentHeight = self?.scrollView.contentSize.height,
               let maxScreenHeight = self?.maxScreenHeight(scrollViewContentHeight - 10) {
                self?.scrollViewHeightAnchorConstraint.constant = maxScreenHeight
            }
        }
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didCreateShareLinkNotifName, object: viewModel, queue: nil) { [weak self] notif in
            guard let shareVO = self?.viewModel?.shareVO, let shareURL = shareVO.shareURL else { return }
            self?.shareURL = shareURL
            
            self?.loadSubviews()
        }
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didUpdateSharesNotifName, object: viewModel, queue: nil) { [weak self] notif in
            guard let fileViewModel = self?.viewModel?.fileViewModel else { return }
            self?.fileViewModel = fileViewModel
            
            self?.loadSubviews()
        }
    }
    
    func loadSubviews() {
        stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        if selectedItemCount == nil {
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
        }
        setupMenuView()
    }
    
    func addSeparatorView() {
        let separatorContainer = UIView()
        let bottomSeparator = UIView()
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparator.backgroundColor = .lightGray
        separatorContainer.addSubview(bottomSeparator)
        
        NSLayoutConstraint.activate([
            bottomSeparator.leadingAnchor.constraint(equalTo: separatorContainer.leadingAnchor, constant: -24),
            bottomSeparator.trailingAnchor.constraint(equalTo: separatorContainer.trailingAnchor, constant: 24),
            bottomSeparator.bottomAnchor.constraint(equalTo: separatorContainer.bottomAnchor, constant: 0),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        stackView.addArrangedSubview(separatorContainer)
    }
    
    func setupPermissionView() {
        let permissionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        permissionLabel.text = "Permission".localizedUppercase
        permissionLabel.font = TextFontStyle.style30.font
        permissionLabel.textColor = UIColor.middleGray
        permissionLabel.setTextSpacingBy(value: 0.8)
        
        let permissionValueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        permissionValueLabel.text = fileViewModel.accessRole.groupName
        permissionValueLabel.font = TextFontStyle.style34.font
        permissionValueLabel.textColor = .dustyGray
        
        let subStackView = UIStackView(arrangedSubviews: [permissionLabel, permissionValueLabel])
        subStackView.axis = .vertical
        subStackView.spacing = 8
        subStackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(subStackView)
        
        addSeparatorView()
    }
    
    func setupInitiatedByView() {
        let initiatedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        initiatedLabel.text = "Initiated by".localizedUppercase
        initiatedLabel.font = TextFontStyle.style30.font
        initiatedLabel.textColor = UIColor.middleGray
        initiatedLabel.setTextSpacingBy(value: 0.8)
        stackView.addArrangedSubview(initiatedLabel)
        
        let imageView = UIImageView(image: UIImage.profile)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        if let url = URL(string: fileViewModel.sharedByArchive?.thumbnail) {
            imageView.sd_setImage(with: url)
        }
        
        let initiatedValueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        initiatedValueLabel.text = "The \(fileViewModel.sharedByArchive?.name ?? "") Archive"
        initiatedValueLabel.font = TextFontStyle.style34.font
        initiatedValueLabel.textColor = .dustyGray
        
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
        stackView.addArrangedSubview(subStackView)
        
        addSeparatorView()
    }
    
    func setupSharedWithView() {
        reloadArchivesStackView()
        if stackView.arrangedSubviews.contains(archivesStackView!) == false {
            stackView.addArrangedSubview(archivesStackView!)
        }
        
        if fileViewModel.minArchiveVOS.count > 2 && showAllArchives == false {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            var image: UIImage? = nil
            image = UIImage(systemName: "chevron.down")?.templated
            
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tintColor = .primary
            imageView.contentMode = .scaleAspectFit
            containerView.addSubview(imageView)
            
            let label = UILabel(frame: CGRect.zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "View all".localized()
            label.textColor = .primary
            label.font = TextFontStyle.style34.font
            containerView.addSubview(label)
            
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(showAllArchivesButtonPressed(_:)), for: .touchUpInside)
            containerView.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
                button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
                button.heightAnchor.constraint(equalToConstant: 50),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
                imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
                imageView.widthAnchor.constraint(equalToConstant: 30),
                label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
                label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
            ])
            
            stackView.addArrangedSubview(containerView)
        }
        
        addSeparatorView()
    }
    
    func reloadArchivesStackView() {
        var subviews: [UIView] = []
        archivesStackView?.arrangedSubviews.forEach({ view in
            view.removeFromSuperview()
        })
        
        let sharedWithLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        let attributedString = NSMutableAttributedString(string: "Shared with (\(fileViewModel.minArchiveVOS.count))".localizedUppercase, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.middleGray], range: NSRange(location: 0, length: 11))
        sharedWithLabel.attributedText = attributedString
        sharedWithLabel.font = TextFontStyle.style30.font
        sharedWithLabel.setTextSpacingBy(value: 0.8)
        NSLayoutConstraint.activate([
            sharedWithLabel.heightAnchor.constraint(equalToConstant: 40)
        ])

        let manageSharingLabel = UILabel(frame: .zero)
        manageSharingLabel.text = "Manage sharing".localized()
        manageSharingLabel.font = TextFontStyle.style35.font
        manageSharingLabel.textColor = .primary
        
        let manageSharingImageView = UIImageView(image: UIImage(named: "manageSharing")?.templated)
        manageSharingImageView.tintColor = .primary
        manageSharingImageView.contentMode = .scaleAspectFit
        
        let arrangedSubviews: [UIView]
        if menuItems.firstIndex(where: { $0.type == .shareToPermanent }) != nil {
            arrangedSubviews = [sharedWithLabel, manageSharingLabel, manageSharingImageView]
        } else {
            arrangedSubviews = [sharedWithLabel]
        }
        
        let headerStackView = UIStackView(arrangedSubviews: arrangedSubviews)
        headerStackView.axis = .horizontal
        headerStackView.spacing = 8
        
        if menuItems.firstIndex(where: { $0.type == .shareToPermanent }) != nil {
            let manageSharingButton = UIButton(type: .custom)
            manageSharingButton.translatesAutoresizingMaskIntoConstraints = false
            manageSharingButton.addTarget(self, action: #selector(manageLinkAction), for: .touchUpInside)
            headerStackView.addSubview(manageSharingButton)
            NSLayoutConstraint.activate([
                manageSharingButton.leadingAnchor.constraint(equalTo: manageSharingLabel.leadingAnchor, constant: 0),
                manageSharingButton.trailingAnchor.constraint(equalTo: manageSharingImageView.trailingAnchor, constant: 0),
                manageSharingButton.topAnchor.constraint(equalTo: manageSharingLabel.topAnchor, constant: 0),
                manageSharingButton.bottomAnchor.constraint(equalTo: manageSharingLabel.bottomAnchor, constant: 0)
            ])
        }
        
        subviews.append(headerStackView)
        
        let maxArchivesShown = showAllArchives ? fileViewModel.minArchiveVOS.count : min(fileViewModel.minArchiveVOS.count, 2)
        for (idx, archive) in fileViewModel.minArchiveVOS[0 ..< maxArchivesShown].enumerated() {
            let accessRole = ShareStatus.status(forValue: archive.shareStatus) == .pending  ? "Pending...".localized() : AccessRole.roleForValue(archive.accessRole).groupName
            
            let archiveStackView = archiveStackView(withArchiveName: "The \(archive.name) Archive", role: accessRole, imagePath: archive.thumbnail, tag: idx + 1)
            subviews.append(archiveStackView)
        }
        
        if archivesStackView == nil {
            let subStackView = UIStackView(arrangedSubviews: subviews)
            subStackView.axis = .vertical
            subStackView.spacing = 8
            subStackView.translatesAutoresizingMaskIntoConstraints = false

            archivesStackView = subStackView
        } else {
            subviews.forEach { view in
                archivesStackView?.addArrangedSubview(view)
            }
        }
    }
    
    func archiveStackView(withArchiveName name: String, role: String, imagePath: String, tag: Int) -> UIView {
        let imageView = UIImageView(image: UIImage.profile)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30)
        ])
        if let url = URL(string: imagePath) {
            imageView.sd_setImage(with: url)
        }
        
        let archiveNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        archiveNameLabel.text = name
        archiveNameLabel.font = TextFontStyle.style34.font
        archiveNameLabel.textColor = .dustyGray
        
        let roleContainer = UIView(frame: .zero)
        roleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // RoleBGView is needed because roleContainer is too tall otherwise.
        let roleBGView = UIView(frame: .zero)
        roleBGView.translatesAutoresizingMaskIntoConstraints = false
        if !role.lowercased().contains("pending") { roleBGView.backgroundColor = .paleYellow }
        roleBGView.layer.cornerRadius = 3
        roleBGView.layer.masksToBounds = true
        roleContainer.addSubview(roleBGView)
        
        let accessRoleLabel = UILabel(frame: .zero)
        accessRoleLabel.translatesAutoresizingMaskIntoConstraints = false
        accessRoleLabel.text = role.uppercased()
        accessRoleLabel.textColor = .primary
        accessRoleLabel.font = TextFontStyle.style36.font
        accessRoleLabel.setTextSpacingBy(value: 0.8)
        
        accessRoleLabel.textAlignment = .center
        archiveNameLabel.setContentCompressionResistancePriority(UILayoutPriority(249), for: .horizontal)
        archiveNameLabel.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
        roleContainer.addSubview(accessRoleLabel)
        
        NSLayoutConstraint.activate([
            accessRoleLabel.leadingAnchor.constraint(equalTo: roleContainer.leadingAnchor, constant: 8),
            accessRoleLabel.trailingAnchor.constraint(equalTo: roleContainer.trailingAnchor, constant: -8),
            accessRoleLabel.centerYAnchor.constraint(equalTo: roleContainer.centerYAnchor, constant: 0),
            accessRoleLabel.heightAnchor.constraint(equalToConstant: 18),
            accessRoleLabel.leadingAnchor.constraint(equalTo: roleBGView.leadingAnchor, constant: 8),
            accessRoleLabel.trailingAnchor.constraint(equalTo: roleBGView.trailingAnchor, constant: -8),
            accessRoleLabel.topAnchor.constraint(equalTo: roleBGView.topAnchor, constant: 0),
            accessRoleLabel.bottomAnchor.constraint(equalTo: roleBGView.bottomAnchor, constant: 0)
        ])
        
        let archiveStackView = UIStackView(arrangedSubviews: [imageView, archiveNameLabel, roleContainer])
        archiveStackView.axis = .horizontal
        archiveStackView.spacing = 8
        archiveStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            archiveStackView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return archiveStackView
    }
    
    func setupShareLink() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        
        let imageView = UIImageView(image: UIImage(named: "Get Link")?.templated ?? .placeholder.templated)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        containerView.addSubview(imageView)
        
        let linkLabel = UILabel()
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        linkLabel.text = shareURL
        linkLabel.font = TextFontStyle.style13.font
        linkLabel.textColor = .mainPurple
        linkLabel.textAlignment = .left
        linkLabel.minimumScaleFactor = 0.7
        containerView.addSubview(linkLabel)
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(shareLinkButtonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        
        var shareImageView: UIImageView = UIImageView()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .light, scale: .small)
        shareImageView = UIImageView(image: UIImage(systemName: "square.and.arrow.up", withConfiguration: imageConfig)?.templated)

        shareImageView.translatesAutoresizingMaskIntoConstraints = false
        shareImageView.tintColor = .primary
        shareImageView.contentMode = .scaleAspectFit
        containerView.addSubview(shareImageView)
        
        let shareButton = UIButton(type: .custom)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(shareLinkButtonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: linkLabel.leadingAnchor, constant: -8),
            linkLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
            button.leadingAnchor.constraint(equalTo: linkLabel.leadingAnchor, constant: 0),
            button.trailingAnchor.constraint(equalTo: linkLabel.trailingAnchor, constant: 0),
            button.topAnchor.constraint(equalTo: linkLabel.topAnchor, constant: 0),
            button.bottomAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 0),
            shareImageView.leadingAnchor.constraint(equalTo: linkLabel.trailingAnchor, constant: 16),
            shareImageView.widthAnchor.constraint(equalToConstant: 20),
            shareImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0),
            shareImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            shareButton.leadingAnchor.constraint(equalTo: shareImageView.leadingAnchor, constant: 0),
            shareButton.trailingAnchor.constraint(equalTo: shareImageView.trailingAnchor, constant: 0),
            shareButton.topAnchor.constraint(equalTo: shareImageView.topAnchor, constant: 0),
            shareButton.bottomAnchor.constraint(equalTo: shareImageView.bottomAnchor, constant: 0),
            containerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        stackView.addArrangedSubview(containerView)
        
        addSeparatorView()
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
            if file.permissions.contains(.ownership) && menuItems.firstIndex(where: { $0.type == .shareToPermanent }) != nil && fileViewModel.minArchiveVOS.isEmpty {
                stackView.addArrangedSubview(menuItem(withName: "Share management".localized(), iconName: "manageSharing", tag: -101))
            }
            if file.type.isFolder == false, let menuIndex = menuItems.firstIndex(where: { $0.type == .shareToAnotherApp }) {
                stackView.addArrangedSubview(menuItem(withName: "Share to Another App".localized(), iconName: "Share Other", tag: menuIndex + 1))
            }
        }
        if let menuIndex = menuItems.firstIndex(where: { $0.type == .unshare }) {
            stackView.addArrangedSubview(menuItem(withName: "Leave share".localized(), iconName: "leaveShare", tag: menuIndex + 1, color: .paleRed))
        }
        if file.permissions.contains(.delete), let menuIndex = menuItems.firstIndex(where: { $0.type == .delete }) {
            stackView.addArrangedSubview(menuItem(withName: "Delete".localized(), iconName: "Delete-1", tag: menuIndex + 1, color: .paleRed))
        }
    }
    
    func menuItem(withName name: String, iconName: String, tag: Int, color: UIColor? = nil) -> UIView {
        let imageView = UIImageView(image: UIImage(named: iconName)?.templated ?? .placeholder)
        if let color = color {
            imageView.tintColor = color
        } else {
            imageView.tintColor = .primary
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24)
        ])
        
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        nameLabel.text = name
        nameLabel.font = TextFontStyle.style7.font
        if let color = color {
            nameLabel.textColor = color
        }
        
        let itemStackView = UIStackView(arrangedSubviews: [imageView, nameLabel])
        itemStackView.axis = .horizontal
        itemStackView.spacing = 8
        itemStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.accessibilityIdentifier = name
        containerView.addSubview(itemStackView)
        
        let button = UIButton(type: .custom)
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
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
    
    @objc func manageLinkAction() {
        guard
            let manageLinkVC = UIViewController.create(withIdentifier: .shareManagement, from: .share) as? ShareManagementViewController
        else {
            return
        }
        
        manageLinkVC.viewModel = viewModel
        
        let navController = NavigationController(rootViewController: manageLinkVC)
        present(navController, animated: true, completion: nil)
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
    
    func maxScreenHeight(_ compareWith: CGFloat) -> CGFloat{
        min(compareWith, view.frame.height - navigationBarHeight)
    }
    
    @objc func showAllArchivesButtonPressed(_ sender: Any) {
        showAllArchives = true
        
        loadSubviews()
        view.layoutIfNeeded()
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
    
    @objc func overlayTapped(_ sender: UIGestureRecognizer) {
        dismiss(animated: true)
    }
    
    @objc private func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            initialCenter = contentView.center
            previousYTranslation = 0
            
        case .changed:
            let translation = sender.translation(in: view)
            let deltaTranslation = translation.y - previousYTranslation
            previousYTranslation = translation.y
            
            if scrollViewHeightAnchorConstraint.constant - deltaTranslation >= maxScreenHeight(scrollView.contentSize.height + 70) {
                scrollViewHeightAnchorConstraint.constant = maxScreenHeight(scrollView.contentSize.height + 70)
            } else if scrollViewHeightAnchorConstraint.constant - deltaTranslation <= scrollViewInitialHeight {
                scrollViewHeightAnchorConstraint.constant -= deltaTranslation / 2
            } else {
                scrollViewHeightAnchorConstraint.constant -= deltaTranslation
            }
            
        case .ended, .cancelled:
            if scrollViewHeightAnchorConstraint.constant < scrollViewInitialHeight - 70 {
                dismiss(animated: true)
            } else if scrollViewHeightAnchorConstraint.constant - scrollViewInitialHeight > (maxScreenHeight(scrollView.contentSize.height + 70) - scrollViewInitialHeight) / 2 {
                scrollViewHeightAnchorConstraint.constant = maxScreenHeight(scrollView.contentSize.height + 70)
                isExpanded = true
                
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut]) {
                    self.view.layoutIfNeeded()
                } completion: { finished in
                    
                }

            } else {
                scrollViewHeightAnchorConstraint.constant = scrollViewInitialHeight
                isExpanded = false
                
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut]) {
                    self.view.layoutIfNeeded()
                } completion: { finished in
                    
                }
            }
            
            scrollView.isScrollEnabled = true
            
        default:
            break
        }
    }
}

extension FileMenuViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension FileMenuViewController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: .to)
        
        if toVC == self {
            transitionContext.containerView.addSubview(self.view)
            
            overlayView.alpha = 0
            contentViewBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 1
                self.view.layoutIfNeeded()
            } completion: { finished in
                transitionContext.completeTransition(true)
            }
        } else {
            contentViewBottomConstraint.constant = contentView.frame.height
            
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { finished in
                self.view.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
}

extension FileMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isExpanded == false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: contentView)
        let isLocationInScrollView = scrollView.frame.contains(location)
        
        let translation = (gestureRecognizer as! UIPanGestureRecognizer).translation(in: contentView)
        let shouldIgnoreScrollView = (scrollView.contentOffset.y == 0 && translation.y > 0) ||
                                     (translation.y < 0 && isExpanded == false)
        
        let shouldBegin = isLocationInScrollView == false || shouldIgnoreScrollView
        
        if shouldBegin {
            scrollView.isScrollEnabled = false
        }
        
        return shouldBegin
    }
}
