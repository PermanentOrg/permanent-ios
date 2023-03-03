//
//  TagManagementViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.10.2022.
//

import UIKit

class TagManagementViewController: BaseViewController<ManageTagsViewModel> {
    
    @IBOutlet weak var archiveTitleNameLabel: UILabel!
    @IBOutlet weak var archiveTitleTagsCountLabel: UILabel!
    @IBOutlet weak var searchTags: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: FABView!
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ManageTagsViewModel()
        
        initUI()
        initCollectionView()
        viewModel?.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: ManageTagsViewModel.didUpdateTagsNotification, object: nil, queue: nil) { [weak self] notif in
            self?.updateTagsNumber()
            self?.collectionView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: ManageTagsViewModel.isLoadingNotification, object: nil, queue: nil) { [weak self] notif in
            if let isLoading = self?.viewModel?.isLoading, isLoading {
                self?.showSpinner()
            } else {
                self?.hideSpinner()
            }
        }
        NotificationCenter.default.addObserver(forName: ManageTagsViewModel.showBannerNotification, object: nil, queue: nil) { [weak self] notif in
            if let notifUserInfo = notif.userInfo,
               let message = notifUserInfo["message"] as? String {
                self?.view.showNotificationBanner(title: message)
            }
        }
    }
    
    func initUI() {
        title = "Manage Tags".localized()
        addDismissKeyboardGesture()
        
        overlayView.frame = view.bounds
        view.addSubview(overlayView)
        overlayView.backgroundColor = .bgOverlay
        overlayView.alpha = 0
        
        archiveTitleNameLabel.font = Text.style35.font
        archiveTitleNameLabel.textColor = .darkBlue
        
        archiveTitleTagsCountLabel.font = Text.style34.font
        archiveTitleTagsCountLabel.textColor = .lightGray
        
        if let archiveName = AuthenticationManager.shared.session?.selectedArchive?.fullName {
            archiveTitleNameLabel.text = "The \(archiveName) Archive Tags"
            updateTagsNumber()
        } else {
            archiveTitleNameLabel.text = "Loading..."
        }
        
        searchTags.updateHeight(height: 40, radius: 2)
        if #available(iOS 13.0, *) {
            searchTags.searchTextField.font = Text.style39.font
        }
        searchTags.setPlaceholderTextColor(.lightGray)
        searchTags.tintColor = .lightGray
        searchTags.searchTextPositionAdjustment = UIOffset(horizontal: 8, vertical: 0)
        searchTags.barTintColor = .white
        searchTags.backgroundColor = .white
        
        addButton.delegate = self
        searchTags.delegate = self
    }
    
    func initCollectionView() {
        collectionView.register(ArchiveSettingsTagCollectionViewCell.nib(), forCellWithReuseIdentifier: ArchiveSettingsTagCollectionViewCell.identifier)
        collectionView.register(ArchiveSettingsTagsHeaderCollectionView.nib(), forSupplementaryViewOfKind: ArchiveSettingsTagsHeaderCollectionView.kind, withReuseIdentifier: ArchiveSettingsTagsHeaderCollectionView.identifier)
        
        collectionView.backgroundColor = .clear
        collectionView.indicatorStyle = .white
        
        let flowLayout = UICollectionViewFlowLayout()
        collectionView.collectionViewLayout = flowLayout
    }
    
    func updateTagsNumber() {
        guard let tagsNumber = viewModel?.tags.count else {
            archiveTitleTagsCountLabel.text = nil
            return
        }
        
        archiveTitleTagsCountLabel.text = "(\(String(tagsNumber)))"
    }
}

// MARK: - FABView Delegate
extension TagManagementViewController: FABViewDelegate {
    func didTap() {
        let tagsOptions = UIViewController.create(withIdentifier: .tagsOptions, from: .archiveSettings) as! FABTagsManagementActionSheet
        tagsOptions.menuType = .newTag
        tagsOptions.viewModel = viewModel
        tagsOptions.modalPresentationStyle = .custom
        tagsOptions.transitioningDelegate = tagsOptions
        self.present(tagsOptions, animated: true)
    }
}

// MARK: - SearchBar Delegate
extension TagManagementViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel?.searchTags(withText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
        
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location >= 16 { return false }
        return true
    }
}

// MARK: - CollectionView DataSource
extension TagManagementViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.sortedTags.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArchiveSettingsTagCollectionViewCell.identifier, for: indexPath) as! ArchiveSettingsTagCollectionViewCell
        
        if let tagName = viewModel?.sortedTags[indexPath.item] {
            cell.configure(tagName: tagName.tagVO.name)
            
            cell.rightSideButtonAction = {
                self.showActionDialog(styled: .updatedSimpleWithDescription, withTitle: "Delete Tags".localized(), description: "Are you sure you want to delete the tags from all items in the current archive?".localized(), positiveButtonTitle: "Delete", positiveAction: { [weak self] in
                    self?.actionDialog?.dismiss()
                    self?.viewModel?.deleteTag(index: indexPath.item, completion: { error in
                        if let _ = error {
                            self?.showErrorAlert(message: .errorMessage)
                        }
                    })
                }, overlayView: self.overlayView )
            }
            
            cell.editButtonAction = { [weak self] in
                let tagsOptions = UIViewController.create(withIdentifier: .tagsOptions, from: .archiveSettings) as! FABTagsManagementActionSheet
                tagsOptions.menuType = .editTag
                tagsOptions.index = indexPath.item
                tagsOptions.viewModel = self?.viewModel
                tagsOptions.modalPresentationStyle = .custom
                tagsOptions.transitioningDelegate = tagsOptions.self
                self?.present(tagsOptions, animated: true)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = UICollectionReusableView()
        switch kind {
        case ArchiveSettingsTagsHeaderCollectionView.kind:
            reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ArchiveSettingsTagsHeaderCollectionView.identifier, for: indexPath) as! ArchiveSettingsTagsHeaderCollectionView
            return reusableView
        default:
            return reusableView
        }
    }
}

//MARK: - CollectionView FlowLayout Delegate
extension TagManagementViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width
        return CGSize(width: cellWidth, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let cellWidth = collectionView.bounds.width
        return CGSize(width: cellWidth, height: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 28, left: 0, bottom: 0, right: 0)
    }
}
