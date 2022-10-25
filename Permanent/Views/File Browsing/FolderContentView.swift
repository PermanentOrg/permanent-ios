//
//  FolderContentView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation
import UIKit
import SkeletonView

class FolderContentView: UIView {
    var viewModel: FolderContentViewModel? {
        didSet {
            collectionView.reloadData()
            
            if let viewModel = viewModel, viewModel.isLoading {
                showAnimatedGradientSkeleton()
            } else {
                hideSkeleton()
                showEmptyFolderIfNeeded()
            }
        }
    }
    let collectionViewLayout: UICollectionViewFlowLayout
    let collectionView: UICollectionView
    let emptyView = EmptyFolderView(title: .emptyFolderMessage, image: .emptyFolder)
    
    init(viewModel: FolderContentViewModel? = nil) {
        self.viewModel = viewModel
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(frame: .zero)
        
        initUI()
        
        NotificationCenter.default.addObserver(forName: FolderContentViewModel.didUpdateFilesNotification, object: nil, queue: nil) { [weak self] notif in
            guard let self = self,
            let notifObj = notif.object as? FolderContentViewModel,
                  notifObj.folder == self.viewModel?.folder
            else {
                return
            }
            
            self.hideSkeleton()
            self.showEmptyFolderIfNeeded()
            self.collectionView.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        backgroundColor = .backgroundPrimary
        isSkeletonable = true
        collectionView.isSkeletonable = true
        
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
        addSubview(collectionView)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = flowLayout
        collectionView.collectionViewLayout.invalidateLayout()
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyView)
        showEmptyFolderIfNeeded()
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            emptyView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 0),
            emptyView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: 0),
            emptyView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 0),
            emptyView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 0),
        ])
        
        showAnimatedGradientSkeleton()
    }
    
    func invalidateLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
    
    func showEmptyFolderIfNeeded() {
        if viewModel?.isLoading == false && viewModel?.files.isEmpty == true {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension FolderContentView: UICollectionViewDelegateFlowLayout, SkeletonCollectionViewDataSource {
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        let isGridView = (viewModel?.isGridView ?? false) == true
        return isGridView ? "FileGridCell" : "FileCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, prepareCellForSkeleton cell: UICollectionViewCell, at indexPath: IndexPath) {
        guard let cell = cell as? FileCollectionViewCell else { return }
        
        cell.fileNameLabel.text = "Long file name text file, test test test"
        cell.fileDateLabel.text = "2022-10-10"
    }

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
        let listItemSize = CGSize(width: collectionView.bounds.width - 12, height: 70)
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
