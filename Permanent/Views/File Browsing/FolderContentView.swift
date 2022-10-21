//
//  FolderContentView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation
import UIKit

class FolderContentView: UIView {
    var viewModel: FolderContentViewModel? {
        didSet {
            collectionView.reloadData()
            
            activityIndicator.isHidden = !(viewModel?.isLoading ?? false)
            activityIndicator.startAnimating()
            collectionView.isHidden = viewModel?.isLoading ?? false
        }
    }
    let collectionViewLayout: UICollectionViewFlowLayout
    let collectionView: UICollectionView
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
    
    init(viewModel: FolderContentViewModel? = nil) {
        self.viewModel = viewModel
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(frame: .zero)
        
        initUI()
        
        NotificationCenter.default.addObserver(forName: FolderContentViewModel.didUpdateFilesNotification, object: nil, queue: nil) { [weak self] notif in
            guard let self = self,
            let notifObj = notif.object as? FolderContentViewModel,
                  notifObj.folder == self.viewModel?.folder
            else {
                return
            }
            
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            self.collectionView.isHidden = false
            self.collectionView.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        backgroundColor = .backgroundPrimary
        
        activityIndicator.tintColor = .gray
        activityIndicator.startAnimating()
        activityIndicator.isHidden = !(viewModel?.isLoading ?? false)
        addSubview(activityIndicator)
        
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isHidden = viewModel?.isLoading ?? false
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = flowLayout
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func invalidateLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension FolderContentView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel?.numberOfSections() ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfItems(inSection: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let isGridView = (viewModel?.isGridView ?? false) == true
        
        let reuseIdentifier: String
        if indexPath.section == FileListType.synced.rawValue {
            reuseIdentifier = isGridView ? "FileGridCell" : "FileCell"
        } else {
            reuseIdentifier = "FileCell"
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileCollectionViewCell
        if let file = viewModel?.fileForRow(atIndexPath: indexPath) {
            cell.updateCell(model: file, fileAction: .none, isGridCell: isGridView, isSearchCell: false)
        }
        
        cell.moreButton.isHidden = true
        cell.rightButtonImageView.isHidden = true
        cell.rightButtonTapAction = nil
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemSize = CGSize(width: collectionView.bounds.width, height: 70)
        // Horizontal layout: |-6-cell-6-cell-6-|. 6*3/2 = 9
        // Vertical size: 30 is the height of the title label
        let gridItemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 9, height: UIScreen.main.bounds.width / 2 + 30)
        
        if indexPath.section == FileListType.synced.rawValue {
            let isGridView = (viewModel?.isGridView ?? false) == true
            return isGridView ? gridItemSize : listItemSize
        } else {
            return listItemSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let file = viewModel?.fileForRow(atIndexPath: indexPath), file.fileStatus == .synced && file.thumbnailURL != nil else { return }
        
        viewModel?.didSelectFile(file)
        // Call Delegate
        
//        if file.type.isFolder {
//            let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
//            navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
//                self.backButton.isHidden = false
//                self.directoryLabel.text = file.name
//            })
//        } else {
//            if viewModel.isPickingImage {
//                handleImagePickerSelection(file: file)
//            } else {
//                handlePreviewSelection(file: file)
//            }
//        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        if kind == UICollectionView.elementKindSectionHeader {
//            let section = indexPath.section
//
//            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! FileCollectionViewHeader
//            headerView.leftButtonTitle = viewModel?.title(forSection: section)
//            if viewModel?.shouldPerformAction(forSection: section) == true {
//                headerView.leftButtonAction = { [weak self] header in self?.headerButtonAction(UIButton()) }
//            } else {
//                headerView.leftButtonAction = nil
//            }
//
//            if viewModel?.hasCancelButton(forSection: section) == true {
//                headerView.rightButtonTitle = "Cancel All".localized()
//                headerView.rightButtonAction = { [weak self] header in self?.cancelAllUploadsAction(UIButton()) }
//            } else {
//                headerView.rightButtonTitle = nil
//                headerView.rightButtonAction = nil
//            }
//
//            return headerView
//        }
//
//        return UICollectionReusableView()
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        let height: CGFloat = viewModel?.numberOfRowsInSection(section) != 0 ? 40 : 0
//        return CGSize(width: UIScreen.main.bounds.width, height: height)
//    }

}
