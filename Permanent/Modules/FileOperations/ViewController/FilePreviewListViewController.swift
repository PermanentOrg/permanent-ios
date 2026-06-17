//
//  FilePreviewListViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 20.04.2021.
//

import UIKit

class FilePreviewListViewController: BaseViewController<FilesViewModel> {
    var pageVC: UIPageViewController!

    let controllersCache: NSCache<NSNumber, FilePreviewViewController> = NSCache<NSNumber, FilePreviewViewController>()
    
    var filteredFiles: [FileModel] {
        viewModel?.viewModels.filter({ $0.type.isFolder == false }) ?? []
    }

    var currentFile: FileModel!
    var isFromNotification: Bool = false
    
    // Transition Variables
    var nextFile: FileModel?
    var nextTitle: String?
    var hasChanges: Bool = false

    // Info (details) and share/more both lead to network-dependent screens — disabled offline.
    private weak var infoBarButton: UIBarButtonItem?
    private weak var shareBarButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = currentFile.name

        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all

        setupPageVC()
        setupNavigationBar()

        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateData(_:)), name: .filePreviewVMDidSaveData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReachabilityChanged), name: ReachabilityManager.reachabilityDidChangeNotifName, object: nil)
    }

    @objc private func onReachabilityChanged() {
        updateNetworkDependentButtons()
    }

    /// Details (info) shows record-backed metadata and the share menu performs network
    /// actions — neither works offline, so disable both when there's no connection.
    private func updateNetworkDependentButtons() {
        let connected = ReachabilityManager.shared.isConnected
        infoBarButton?.isEnabled = connected
        shareBarButton?.isEnabled = connected
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation bar is always visible when view appears
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Double-check navigation bar is visible after view fully appears
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setupPageVC() {
        pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageVC.dataSource = self
        pageVC.delegate = self
        
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.frame = view.bounds
        pageVC.didMove(toParent: self)
        
        // If opened from notification with empty viewModel, show single file
        if isFromNotification && filteredFiles.isEmpty {
            let fileDetailsVC = createFilePreviewViewController(for: currentFile)
            pageVC.setViewControllers([fileDetailsVC], direction: .forward, animated: false, completion: nil)
        } else if let indexOfFileVC = filteredFiles.firstIndex(of: currentFile) {
            let fileDetailsVC = dequeueViewController(atIndex: indexOfFileVC)!
            
            pageVC.setViewControllers([fileDetailsVC], direction: .forward, animated: false, completion: nil)
        }
    }
    
    private func createFilePreviewViewController(for file: FileModel) -> FilePreviewViewController {
        let filePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
        filePreviewVC.file = file
        filePreviewVC.viewModel = FilePreviewViewModel(file: file)
        
        // If opened from notification, pass close action to child VC
        if isFromNotification {
            filePreviewVC.closeAction = { [weak self] in
                self?.closeButtonAction(self as Any)
            }
        }
        
        // Load the file content
        filePreviewVC.view.isHidden = false // preload the view
        filePreviewVC.loadVM()
        
        return filePreviewVC
    }
    
    func setupNavigationBar() {
        let shareButton = UIBarButtonItem(image: .more, style: .plain, target: self, action: #selector(shareButtonAction(_:)))
        shareButton.accessibilityIdentifier = "filePreviewShareButton"
        
        let infoButton = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(infoButtonAction(_:)))
        infoButton.accessibilityIdentifier = "filePreviewInfoButton"
        navigationItem.rightBarButtonItems = [shareButton, infoButton]

        infoBarButton = infoButton
        shareBarButton = shareButton
        updateNetworkDependentButtons()
        
        let leftButtonImage: UIImage!
        leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        
        let closeButton = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        closeButton.accessibilityIdentifier = "filePreviewCloseButton"
        navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        (navigationController as! FilePreviewNavigationController).filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareButtonAction(_ sender: Any) {
        (pageVC.viewControllers?.first as! FilePreviewViewController).showShareMenu(sender)
    }
    
    @objc private func infoButtonAction(_ sender: Any) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        
        let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap, from: .main) as! FileDetailsViewController
        fileDetailsVC.file = currentFile
        fileDetailsVC.viewModel = viewModel
        fileDetailsVC.delegate = self
        
        let navControl = FilePreviewNavigationController(rootViewController: fileDetailsVC)
        navControl.modalPresentationStyle = .fullScreen
        present(navControl, animated: false, completion: nil)
    }
    
    @objc func onDidUpdateData(_ notification: Notification) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        if let notifVM = notification.object as? FilePreviewViewModel, notifVM.file == viewModel?.file {
            title = viewModel?.name
            view.showNotificationBanner(title: "Change was saved.".localized())
        }
        
        hasChanges = true
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate
extension FilePreviewListViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let nextVC = pendingViewControllers.first as! FilePreviewViewController
        nextFile = nextVC.file
        nextTitle = nextVC.viewModel?.name
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            title = nextTitle
            currentFile = nextFile
            
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let indexOfFileVC = filteredFiles.firstIndex(of: (viewController as! FilePreviewViewController).file) {
            let dequeuedVC = dequeueViewController(atIndex: Int(indexOfFileVC) - 1)
            
            return dequeuedVC
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let indexOfFileVC = filteredFiles.firstIndex(of: (viewController as! FilePreviewViewController).file) {
            let dequeuedVC = dequeueViewController(atIndex: Int(indexOfFileVC) + 1)
            return dequeuedVC
        }
        
        return nil
    }
    
    @discardableResult
    func dequeueViewController(atIndex index: Int, preloadLeftRightLevel: Int = 0) -> FilePreviewViewController? {
        if let fileDetailsVC = controllersCache.object(forKey: NSNumber(value: index)) {
            // Preload left and right controllers after the current one is loaded
            if preloadLeftRightLevel <= 2 {
                if fileDetailsVC.recordLoaded {
                    dequeueViewController(atIndex: index - 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                    dequeueViewController(atIndex: index + 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                } else {
                    fileDetailsVC.recordLoadedCB = { [weak self] fileDetailsVC in
                        self?.dequeueViewController(atIndex: index - 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                        self?.dequeueViewController(atIndex: index + 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                    }
                }
            }
            
            return fileDetailsVC
        } else if index >= 0 && index < filteredFiles.count {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
            
            // Preload left and right controllers after the current one is loaded
            if preloadLeftRightLevel <= 2 {
                fileDetailsVC.recordLoadedCB = { [weak self] fileDetailsVC in
                    self?.dequeueViewController(atIndex: index - 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                    self?.dequeueViewController(atIndex: index + 1, preloadLeftRightLevel: preloadLeftRightLevel + 1)
                }
            }
            let file = filteredFiles[index]
            fileDetailsVC.file = file
            fileDetailsVC.view.isHidden = false // preload the view
            fileDetailsVC.loadVM()
            
            // If opened from notification, pass close action to child VC
            if isFromNotification {
                fileDetailsVC.closeAction = { [weak self] in
                    self?.closeButtonAction(self as Any)
                }
            }
            
            if let publicArchiveVM = viewModel as? PublicArchiveViewModel {
                fileDetailsVC.viewModel?.publicURL = publicArchiveVM.publicURL(forFile: file)
            }
            
            if let publicArchiveVM = viewModel as? PublicFilesViewModel {
                fileDetailsVC.viewModel?.publicURL = publicArchiveVM.publicURL(forFile: file)
            }
            
            controllersCache.setObject(fileDetailsVC, forKey: NSNumber(value: index))
            
            return fileDetailsVC
        }
        
        return nil
    }
}

extension FilePreviewListViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges == true {
            self.hasChanges = true
        }

        // Called when the details screen closes. The details modal is still presented on
        // top of this preview pager, so dismiss from our presenter (the file list) to tear
        // down both in a single animation — details slides away straight to the file list,
        // without the preview flashing in between. (When this pager is closed directly, its
        // own closeButtonAction handles dismissal instead.)
        let fileListDelegate = (self.navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate
        let changes = self.hasChanges
        let presenter = presentingViewController ?? self
        presenter.dismiss(animated: true) {
            fileListDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: changes)
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        title = viewModel?.name
        
        if hasChanges == true {
            self.hasChanges = true
        }
    }
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        // Forward the request through the navigation controller
        (navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate?.filePreviewNavigationControllerRequestsDownload(self, file: file)
    }
}
