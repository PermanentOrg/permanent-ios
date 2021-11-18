//
//  ProfileViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class ProfilePageViewController: BaseViewController<ProfilePageViewModel> {
    
    var authData: AuthViewModel!
    
    enum CellType {
        case thumbnails
        case segmentedControl
        case archiveGallery
        case about
        case personalInformation
        case onlinePresence
        case milestones
    }
    
    let topSectionCells: [CellType] = [.thumbnails, .segmentedControl]
    var bottomSectionCells: [CellType] = [.archiveGallery]
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ProfilePageViewModel(authData: authData)
        
        initUI()
        
        initCollectionView()
    }
    
    func initUI() {
        if let archiveName = viewModel?.archiveData?.fullName {
            title = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
        view.backgroundColor = .white
        
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        
        collectionView.register(ProfilePageTopCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageTopCollectionViewCell.identifier)
        collectionView.register(ProfilePageMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageMenuCollectionViewCell.identifier)
        
        collectionView.register(ProfilePageArchiveCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier)
        collectionView.register(ProfilePageAboutCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier)
        collectionView.register(ProfilePagePersonInfoCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePagePersonInfoCollectionViewCell.identifier)
        collectionView.register(ProfilePageOnlinePresenceCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier)
        collectionView.register(ProfilePageMilestonesCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageMilestonesCollectionViewCell.identifier)
        
        
        collectionView.register(ProfilePageHeaderCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfilePageHeaderCollectionViewCell.identifier)
        collectionView.register(ProfilePageFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfilePageFooterCollectionViewCell.identifier)
        collectionView.register(ProfilePageEmptyCollectionReusableView.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier)
        collectionView.register(ProfilePageEmptyCollectionReusableView.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    private func segmentedControlChangedAction() -> ((ProfilePageMenuCollectionViewCell) -> Void) {
        return { [weak self] cell in
            guard let strongSelf = self else { return }
            
            if cell.segmentedControl.selectedSegmentIndex == 0 {
                strongSelf.bottomSectionCells = [.archiveGallery]
            } else {
                strongSelf.bottomSectionCells = [.about, .personalInformation, .onlinePresence, .milestones]
            }
            
            strongSelf.collectionView.reloadSections([1])
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ProfilePageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return topSectionCells.count
        } else if section == 1 {
            return bottomSectionCells.count
        }
        
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        let returnedCell: ProfilePageBaseCollectionViewCell
        
        switch currentCellType {
            
        case .thumbnails:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageTopCollectionViewCell.identifier, for: indexPath) as! ProfilePageTopCollectionViewCell
            cell.configure(profileBannerImageUrl: nil, profilePhotoImageUrl: self.viewModel?.archiveData?.thumbURL1000)
            
            returnedCell = cell
            
        case .segmentedControl:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageMenuCollectionViewCell.identifier, for: indexPath) as! ProfilePageMenuCollectionViewCell
            cell.segmentedControlAction = segmentedControlChangedAction()
            
            returnedCell = cell
            
        case .archiveGallery:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier, for: indexPath) as! ProfilePageArchiveCollectionViewCell
            
            returnedCell = cell
            
        case .about:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier, for: indexPath) as! ProfilePageAboutCollectionViewCell
            
            returnedCell = cell
            
        case .personalInformation:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePagePersonInfoCollectionViewCell.identifier, for: indexPath) as! ProfilePagePersonInfoCollectionViewCell
            
            returnedCell = cell
            
        case .onlinePresence:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier, for: indexPath) as! ProfilePageOnlinePresenceCollectionViewCell
            
            returnedCell = cell
            
        case .milestones:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageMilestonesCollectionViewCell.identifier, for: indexPath) as! ProfilePageMilestonesCollectionViewCell
            
            returnedCell = cell
        }
        return returnedCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        switch currentCellType {
            
        case .thumbnails:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        case .segmentedControl:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        case .archiveGallery:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        case .about:
            switch kind {
                
            case UICollectionView.elementKindSectionHeader:
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageHeaderCollectionViewCell.identifier, for: indexPath)
                return headerCell
                
            case UICollectionView.elementKindSectionFooter:
                let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageFooterCollectionViewCell.identifier, for: indexPath)
                return footerCell
                
            default:
                let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
            
                return emptyCell
            }
        case .personalInformation:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        case .onlinePresence:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        case .milestones:
            let emptyCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageEmptyCollectionReusableView.identifier, for: indexPath)
        
            return emptyCell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ProfilePageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        switch currentCellType {
        case .thumbnails:
            return CGSize(width: UIScreen.main.bounds.width, height: 270)
        case .segmentedControl:
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case .about:
            return CGSize(width: UIScreen.main.bounds.width, height: 170)
        case .personalInformation:
            return CGSize(width: UIScreen.main.bounds.width, height: 200)
        case .onlinePresence:
            return CGSize(width: UIScreen.main.bounds.width, height: 150)
        case .milestones:
            return CGSize(width: UIScreen.main.bounds.width, height: 200)
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 120)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: collectionView.frame.width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 0)
    }
}
