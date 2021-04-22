//
//  FilePreviewListViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 20.04.2021.
//

import UIKit

class FilePreviewListViewController: BaseViewController<FilesViewModel> {
    
    var collectionView: UICollectionView!
    
    let controllersCache: NSCache<NSNumber, FilePreviewNavigationController> = NSCache<NSNumber, FilePreviewNavigationController>()
    
    var filteredFiles: [FileViewModel] {
        get {
            viewModel?.viewModels.filter({ $0.type.isFolder == false }) ?? []
        }
    }
    var initialFile: FileViewModel!
    
    var initialScrollDone: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        view.addSubview(collectionView)

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: UICollectionViewCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if (!initialScrollDone) {
            initialScrollDone = true
            let selectedIndex: Int = filteredFiles.firstIndex(of: initialFile) ?? 0
            collectionView.scrollToItem(at: [0, selectedIndex], at: .centeredHorizontally, animated: false)
        }
    }
}

extension FilePreviewListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.viewModels.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewCell.reuseIdentifier, for: indexPath)
        
        guard let viewModel = viewModel else { return cell }

        let file = viewModel.fileForRowAt(indexPath: indexPath)
        
        guard file.fileStatus == .synced else { return cell }
        
        if file.type.isFolder {
        } else if controllersCache.object(forKey: NSNumber(value: indexPath.row)) == nil {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview , from: .main) as! FilePreviewViewController
            fileDetailsVC.file = file
            
            let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: fileDetailsVC)
            controllersCache.setObject(fileDetailsNavigationController, forKey: NSNumber(value: indexPath.row))
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
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
}
