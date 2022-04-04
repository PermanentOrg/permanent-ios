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
}

class PublicGalleryViewController: BaseViewController<PublicGalleryViewModel> {
    
    @IBOutlet weak var archiveImageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var archive: ArchiveVOData!
    var collectionViewSections: [PublicGalleryCellType] = [.onlineArchives]
    var accountArchives: [ArchiveVOData]?
    var popularArchives: [ArchiveVOData]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PublicGalleryViewModel()
        
        initUI()
        initCollectionView()
        updateArchivesList()
        
        searchBar.isUserInteractionEnabled = false
    }
    
    private func initUI() {
        searchBar.updateHeight(height: archiveImageView.frame.height, radius: 2)
        archiveImageView.layer.cornerRadius = archiveImageView.frame.height / 2
        
        title = "Public Gallery".localized()

    }
    
    private func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        //layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        
        collectionView.register(PublicGalleryCellCollectionViewCell.nib(), forCellWithReuseIdentifier: PublicGalleryCellCollectionViewCell.identifier)

        collectionView.register(PublicGalleryHeaderCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PublicGalleryHeaderCollectionViewCell.identifier)
        collectionView.register(PublicGalleryFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PublicGalleryFooterCollectionViewCell.identifier)
    }
    
    func updateCurrentArchive() {
        if let archive = viewModel?.currentArchive(),
           let archiveName: String = archive.fullName,
           let archiveThumbURL: String = archive.thumbURL500 {
            archiveImageView.image = nil
            archiveImageView.load(urlString: archiveThumbURL)
        }
    }
    
    func updateArchivesList() {
        showSpinner()
        
        viewModel?.getAccountInfo({ [self] account, error in
            if error == nil {
                if let currentArchives = self.accountArchives {
                    hideSpinner()
                    
                    viewModel?.allArchives = currentArchives
                    self.accountArchives = nil
                    collectionView.reloadData()
                    updateCurrentArchive()
                } else {
                    viewModel?.getAccountArchives { [self] accountArchives, error in
                        hideSpinner()
                        
                        if error == nil {
                            collectionView.reloadData()
                            updateCurrentArchive()
                        } else {
                            showAlert(title: .error, message: .errorMessage)
                        }
                    }
                }
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
        viewModel?.getPopularArchives({ result, error in
            if error == nil {
                print("worked")
            } else {
                self.showAlert(title: .error, message: .errorMessage)
            }
        })
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
        }
        
        return numberOfItemsInSection
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var returnedCell = UICollectionViewCell()
        
        switch collectionViewSections[indexPath.section] {
        case .onlineArchives:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PublicGalleryCellCollectionViewCell.identifier), for: indexPath) as! PublicGalleryCellCollectionViewCell
    
            cell.configure(archive: viewModel?.userPublicArchives[indexPath.item])
            returnedCell = cell
            
        case .popularPublicArchives:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PublicGalleryCellCollectionViewCell.identifier), for: indexPath) as! PublicGalleryCellCollectionViewCell
            guard let archiveName = viewModel?.publicArchives[indexPath.item].fullName else { return returnedCell }
            
            //cell.configure(title: archiveName)
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
            return UICollectionReusableView()
        default:
            return UICollectionReusableView()
        }
    }
}

extension PublicGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        showSpinner()
        
        switch collectionViewSections[indexPath.section] {
        case .onlineArchives:
            guard let selectedArchive = viewModel?.userPublicArchives[indexPath.item] else { return }
            
            let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
            newRootVC.archiveData = selectedArchive
            let newNav = NavigationController(rootViewController: newRootVC)
            present(newNav, animated: true)
            
        case .popularPublicArchives:
            hideSpinner()
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
}
