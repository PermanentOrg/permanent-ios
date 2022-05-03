//
//  PublicGalleryViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.03.2022.
//

import UIKit

enum PublicGalleryCellType {
    case onlineArchives
    case popularPublicArchives
    case searchResultArchives
}

class PublicGalleryViewController: BaseViewController<PublicGalleryViewModel> {
    @IBOutlet weak var archiveImageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    
    var collectionViewSections: [PublicGalleryCellType] = []
    var accountArchives: [ArchiveVOData]?
    var popularArchives: [ArchiveVOData]?
    var linkIconButton: ButtonAction?
    
    var searchInProgress: Bool = false
    var collectionViewSectionsBeforeSearch: [PublicGalleryCellType] = []
    
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PublicGalleryViewModel()
        
        initUI()
        initCollectionView()
        updateArchivesList()
    }
    
    private func initUI() {
        searchBar.updateHeight(height: archiveImageView.frame.height, radius: 2)
        archiveImageView.layer.cornerRadius = 2
        
        title = "Public Gallery".localized()
        searchBar.placeholder = "Search archives by name".localized()
        backButton.alpha = 0
    }
    
    private func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        
        collectionView.register(PublicGalleryCellCollectionViewCell.nib(), forCellWithReuseIdentifier: PublicGalleryCellCollectionViewCell.identifier)

        collectionView.register(PublicGalleryHeaderCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PublicGalleryHeaderCollectionViewCell.identifier)
        collectionView.register(PublicGalleryFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PublicGalleryFooterCollectionViewCell.identifier)
    }
    
    func updateCurrentArchive() {
        if let archive = viewModel?.currentArchive(),
            let archiveThumbURL: String = archive.thumbURL500 {
            archiveImageView.image = nil
            archiveImageView.load(urlString: archiveThumbURL)
        }
    }
    
    func updateArchivesList() {
        showSpinner()
        
        viewModel?.getArchives({ result in
            self.hideSpinner()
            
            if let userPublicArchivesNbr = self.viewModel?.userPublicArchives.count,
            userPublicArchivesNbr > 0 {
                self.collectionViewSections.append(.onlineArchives)
            }
            
            if let publicArchivesNbr = self.viewModel?.publicArchives.count,
            publicArchivesNbr > 0 {
                self.collectionViewSections.append(.popularPublicArchives)
            }
            
            self.collectionView.reloadData()
            self.updateCurrentArchive()
        })
    }
    
    func updateSections() {
        if searchInProgress {
            if collectionViewSectionsBeforeSearch.isEmpty {
                collectionViewSectionsBeforeSearch = collectionViewSections
                
                UIView.animate(withDuration: 0.3, delay: 0) {
                    self.archiveImageView.alpha = 0
                    self.backButton.alpha = 1
                }
            }
            collectionViewSections.removeAll()
            if let searchArchivesNbr = self.viewModel?.searchPublicArchives.count,
            searchArchivesNbr > 0 {
                collectionViewSections.append(.searchResultArchives)
            }
        } else {
            collectionViewSections.removeAll()
            collectionViewSections = collectionViewSectionsBeforeSearch
            collectionViewSectionsBeforeSearch.removeAll()
            viewModel?.searchPublicArchives.removeAll()
        }
        collectionView.reloadData()
        handleTableBackgroundView()
    }
    
    func handleTableBackgroundView() {
        if viewModel?.searchPublicArchives.isEmpty ?? true && searchInProgress {
            let backgroundView = EmptyFolderView(title: "Search results will appear here.".localized(), image: .emptySearch, positionOffset: CGPoint(x: 0, y: -(collectionView.frame.height / 4)))
            backgroundView.frame = collectionView.bounds
            collectionView.backgroundView = backgroundView
            return
        }
        collectionView.backgroundView = nil
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        view.endEditing(true)
        UIView.animate(withDuration: 0.3, delay: 0) {
            self.archiveImageView.alpha = 1
            self.backButton.alpha = 0
        }
        
        searchBar.text = ""
        searchInProgress = false
        updateSections()
    }
}

extension PublicGalleryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionViewSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItemsInSection = 0
        
        switch collectionViewSections[section] {
        case .onlineArchives:
            numberOfItemsInSection = viewModel?.userPublicArchives.count ?? 0
            
        case .popularPublicArchives:
            numberOfItemsInSection = viewModel?.publicArchives.count ?? 0
            
        case .searchResultArchives:
            numberOfItemsInSection = viewModel?.searchPublicArchives.count ?? 0
        }
        return numberOfItemsInSection
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var returnedCell = UICollectionViewCell()
        
        switch collectionViewSections[indexPath.section] {
        case .onlineArchives:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PublicGalleryCellCollectionViewCell.identifier), for: indexPath) as! PublicGalleryCellCollectionViewCell
    
            cell.configure(archive: viewModel?.userPublicArchives[indexPath.item], section: collectionViewSections[indexPath.section])
            cell.buttonAction = {
                self.openPopUpMenu(url: self.viewModel?.publicProfileURL(archiveNbr: self.viewModel?.userPublicArchives[indexPath.item].archiveNbr))
            }
            returnedCell = cell
            
        case .popularPublicArchives:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PublicGalleryCellCollectionViewCell.identifier), for: indexPath) as! PublicGalleryCellCollectionViewCell
            
            cell.configure(archive: viewModel?.publicArchives[indexPath.item], section: collectionViewSections[indexPath.section])
            cell.buttonAction = {
                self.openPopUpMenu(url: self.viewModel?.publicProfileURL(archiveNbr: self.viewModel?.publicArchives[indexPath.item].archiveNbr))
            }
            returnedCell = cell
            
        case .searchResultArchives:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PublicGalleryCellCollectionViewCell.identifier), for: indexPath) as! PublicGalleryCellCollectionViewCell
            
            cell.configure(archive: viewModel?.searchPublicArchives[indexPath.item], section: collectionViewSections[indexPath.section])
            cell.buttonAction = {
                self.openPopUpMenu(url: self.viewModel?.publicProfileURL(archiveNbr: self.viewModel?.searchPublicArchives[indexPath.item].archiveNbr))
            }
            returnedCell = cell
        }

        return returnedCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PublicGalleryHeaderCollectionViewCell.identifier, for: indexPath) as! PublicGalleryHeaderCollectionViewCell
            headerCell.configure(section: collectionViewSections[indexPath.section])
            return headerCell
            
        case UICollectionView.elementKindSectionFooter:
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PublicGalleryFooterCollectionViewCell.identifier, for: indexPath) as! PublicGalleryFooterCollectionViewCell
            return footerCell
            
        default:
            return UICollectionReusableView()
        }
    }
    
    private func openPopUpMenu(url: URL?) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        self.documentInteractionController.dismissMenu(animated: true)
        
        if let url = url {
            self.documentInteractionController.url = url
            self.documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
            self.documentInteractionController.name = url.localizedName ?? url.lastPathComponent
            self.documentInteractionController.presentOptionsMenu(from: .zero, in: self.view, animated: true)
        }
    }
}

extension PublicGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch collectionViewSections[indexPath.section] {
        case .onlineArchives:
            guard let selectedArchive = viewModel?.userPublicArchives[indexPath.item] else { return }
            
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = selectedArchive
            let newNav = NavigationController(rootViewController: newRootVC)
            present(newNav, animated: true)
            
        case .popularPublicArchives:
            guard let selectedArchive = viewModel?.publicArchives[indexPath.item] else { return }
            
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = selectedArchive
            let newNav = NavigationController(rootViewController: newRootVC)
            present(newNav, animated: true)
            
        case .searchResultArchives:
            guard let selectedArchive = viewModel?.searchPublicArchives[indexPath.item] else { return }
            
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = selectedArchive
            let newNav = NavigationController(rootViewController: newRootVC)
            present(newNav, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 20)
    }
}

extension PublicGalleryViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchInProgress = true
        updateSections()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchInProgress = true
        if searchText.count > 0 {
            viewModel?.searchArchives(byQuery: searchText, handler: { [self] result in
                updateSections()
            })
        } else {
            viewModel?.searchPublicArchives.removeAll()
            updateSections()
        }
    }
}
