//
//  FilePreviewListViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 20.04.2021.
//

import UIKit

class FilePreviewListViewController: BaseViewController<FilesViewModel> {
    
    var collectionView: UICollectionView!
    
    let controllersCache: NSCache<NSNumber, FilePreviewViewController> = NSCache<NSNumber, FilePreviewViewController>()
    
    var filteredFiles: [FileViewModel] {
        get {
            viewModel?.viewModels.filter({ $0.type.isFolder == false }) ?? []
        }
    }

    var currentFile: FileViewModel!
    
    var deviceInRotation: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = currentFile.name
        
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        view.addSubview(collectionView)

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: UICollectionViewCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let selectedIndex: CGFloat = CGFloat(filteredFiles.firstIndex(of: currentFile) ?? 0)

        collectionView.scrollRectToVisible(CGRect(x: view.bounds.width * selectedIndex, y: 0, width: view.bounds.width, height: view.bounds.height), animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        deviceInRotation = true
        coordinator.animate { (ctx) in
            
        } completion: { (ctx) in
            self.collectionView.reloadData()
            self.deviceInRotation = false
        }
    }
    
    @objc func closeButtonAction(_ sender: Any) {
//        filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareButtonAction(_ sender: Any) {
        if let currentIndex = collectionView.indexPathsForVisibleItems.first,
            let fileDetailsNavigationController = controllersCache.object(forKey: NSNumber(value: currentIndex.row)) {
            fileDetailsNavigationController.shareButtonAction(sender)
        }
    }
    
    @objc private func infoButtonAction(_ sender: Any) {
        if let currentIndex = collectionView.indexPathsForVisibleItems.first,
            let fileDetailsNavigationController = controllersCache.object(forKey: NSNumber(value: currentIndex.row)) {
            let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap , from: .main) as! FileDetailsViewController
            fileDetailsVC.file = fileDetailsNavigationController.file
            fileDetailsVC.viewModel = fileDetailsNavigationController.viewModel
            fileDetailsVC.delegate = self
            
            let navControl = FilePreviewNavigationController(rootViewController: fileDetailsVC)
            navControl.modalPresentationStyle = .fullScreen
            present(navControl, animated: false, completion: nil)
            
            fileDetailsVC.title = title ?? fileDetailsNavigationController.file.name
        }
    }
}

extension FilePreviewListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewCell.reuseIdentifier, for: indexPath)

        let file = filteredFiles[indexPath.row]
        
        guard file.fileStatus == .synced else { return cell }
        
        if file.type.isFolder {
        } else if controllersCache.object(forKey: NSNumber(value: indexPath.row)) == nil {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview , from: .main) as! FilePreviewViewController
            fileDetailsVC.file = file
            
            controllersCache.setObject(fileDetailsVC, forKey: NSNumber(value: indexPath.row))
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let fileDetailsNavigationController = controllersCache.object(forKey: NSNumber(value: indexPath.row)) {
            addChild(fileDetailsNavigationController)
            cell.contentView.addSubview(fileDetailsNavigationController.view)
            fileDetailsNavigationController.view.frame = cell.contentView.bounds
            fileDetailsNavigationController.didMove(toParent: self)
            fileDetailsNavigationController.willMoveOnScreen()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let fileDetailsNavigationController = controllersCache.object(forKey: NSNumber(value: indexPath.row)) {
            fileDetailsNavigationController.willMove(toParent: nil)
            fileDetailsNavigationController.view.removeFromSuperview()
            fileDetailsNavigationController.removeFromParent()
            fileDetailsNavigationController.didMove(toParent: nil)
            fileDetailsNavigationController.willMoveOffScreen()
        }
        
        if let currentIndex = collectionView.indexPathsForVisibleItems.first,
           deviceInRotation == false {
            currentFile = filteredFiles[currentIndex.item]
            
            let currentVC = controllersCache.object(forKey: NSNumber(value: currentIndex.item))
            title = currentVC?.title
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
}

extension FilePreviewListViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        dismiss(animated: true) {
            (self.navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if let currentIndex = collectionView.indexPathsForVisibleItems.first {
            let currentVC = controllersCache.object(forKey: NSNumber(value: currentIndex.item))
            currentVC?.title = filePreviewNavigationVC.title
            title = currentVC?.title
        }
    }
}
