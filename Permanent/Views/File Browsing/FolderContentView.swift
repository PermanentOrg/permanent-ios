//
//  FolderContentView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation
import UIKit

class FolderContentView: UIView {
    var viewModel: FolderContentViewModel {
        didSet {
            // update collection view
        }
    }
    let collectionViewLayout: UICollectionViewFlowLayout
    let collectionView: UICollectionView
    
    init(viewModel: FolderContentViewModel) {
        self.viewModel = viewModel
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(frame: .zero)
        
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension FolderContentView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier: String
        if indexPath.section == FileListType.synced.rawValue {
            reuseIdentifier = viewModel.isGridView ? "FileGridCell" : "FileCell"
        } else {
            reuseIdentifier = "FileCell"
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileCollectionViewCell
        let file = viewModel.fileForRow(atIndexPath: indexPath)
        cell.updateCell(model: file, fileAction: .none, isGridCell: viewModel.isGridView, isSearchCell: false)
        
        cell.moreButton.isHidden = true
        cell.rightButtonImageView.isHidden = true
        cell.rightButtonTapAction = nil
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: 70)
        // Horizontal layout: |-6-cell-6-cell-6-|. 6*3/2 = 9
        // Vertical size: 30 is the height of the title label
        let gridItemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 9, height: UIScreen.main.bounds.width / 2 + 30)
        
        if indexPath.section == FileListType.synced.rawValue {
            return viewModel.isGridView ? gridItemSize : listItemSize
        } else {
            return listItemSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let file = viewModel.fileForRow(atIndexPath: indexPath)
        
        guard file.fileStatus == .synced && file.thumbnailURL != nil else { return }
        
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
