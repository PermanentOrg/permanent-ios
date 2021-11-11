//
//  ProfileViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class ProfilePageViewController: BaseViewController<ProfilePageViewModel> {
    
    let archiveName = "Current Profile Archive"
    
    enum CellType {
        case thumbnails
        case segmentedControl
    }
    
    let topSectionCells: [CellType] = [.thumbnails, .segmentedControl]
    var bottomSectionCells: [CellType] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ProfilePageViewModel()
        
        initUI()
        
        initCollectionView()
    }
    
    func initUI() {
        title = archiveName
        view.backgroundColor = .white
        
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        
        collectionView.register(ProfilePageTopCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageTopCollectionViewCell.identifier)
        collectionView.register(ProfilePageMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageMenuCollectionViewCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
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
            returnedCell = cell
        case .segmentedControl:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageMenuCollectionViewCell.identifier, for: indexPath) as! ProfilePageMenuCollectionViewCell
            
            returnedCell = cell
        }
        return returnedCell
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
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 65)
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
}
