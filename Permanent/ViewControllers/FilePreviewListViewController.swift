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
    
    var filteredFiles: [FileViewModel] {
        get {
            viewModel?.viewModels.filter({ $0.type.isFolder == false }) ?? []
        }
    }

    var currentFile: FileViewModel!
    
    // Transition Variables
    var nextFile: FileViewModel? = nil
    var nextTitle: String? = nil
    
    var hasChanges: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = currentFile.name

        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        setupPageVC()
        setupNavigationBar()
    }
    
    func setupPageVC() {
        pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageVC.dataSource = self
        pageVC.delegate = self
        
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.frame = view.bounds
        pageVC.didMove(toParent: self)
        
        let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview , from: .main) as! FilePreviewViewController
        fileDetailsVC.file = currentFile
        
        if let indexOfFileVC = filteredFiles.firstIndex(of: currentFile) {
            controllersCache.setObject(fileDetailsVC, forKey: NSNumber(value: Int(indexOfFileVC)))
        }
        pageVC.setViewControllers([fileDetailsVC], direction: .forward, animated: false, completion: nil)
    }
    
    func setupNavigationBar() {
        let shareButtonImage = UIBarButtonItem.SystemItem.action
        let shareButton = UIBarButtonItem(barButtonSystemItem: shareButtonImage, target: self, action: #selector(shareButtonAction(_:)))
        
        let infoButton = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(infoButtonAction(_:)))
        navigationItem.rightBarButtonItems = [shareButton, infoButton]
        
        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        (navigationController as! FilePreviewNavigationController).filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareButtonAction(_ sender: Any) {
        (pageVC.viewControllers?.first as! FilePreviewViewController).shareButtonAction(sender)
    }
    
    @objc private func infoButtonAction(_ sender: Any) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        
        let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap , from: .main) as! FileDetailsViewController
        fileDetailsVC.file = currentFile
        fileDetailsVC.viewModel = viewModel
        fileDetailsVC.delegate = self
        
        let navControl = FilePreviewNavigationController(rootViewController: fileDetailsVC)
        navControl.modalPresentationStyle = .fullScreen
        present(navControl, animated: false, completion: nil)
        
        fileDetailsVC.title = currentFile.name
    }
}

//MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate
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
    
    func dequeueViewController(atIndex index: Int) -> FilePreviewViewController? {
        if let fileDetailsVC = controllersCache.object(forKey: NSNumber(value: index)) {
            return fileDetailsVC
        } else if index >= 0 && index < filteredFiles.count {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview , from: .main) as! FilePreviewViewController
            fileDetailsVC.file = filteredFiles[index]
            
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
        
        dismiss(animated: true) {
            (self.navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: self.hasChanges)
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        title = viewModel?.name
        
        if hasChanges == true {
            self.hasChanges = true
        }
    }
}
