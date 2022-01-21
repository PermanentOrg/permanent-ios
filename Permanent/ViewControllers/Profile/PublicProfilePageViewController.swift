//
//  ProfileViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class PublicProfilePageViewController: BaseViewController<PublicProfilePageViewModel> {
    var archiveData: ArchiveVOData!
    weak var delegate: PublicArchiveChildDelegate?
    var profileData: [ProfileItemVO] = []
    
    enum CellType {
        case archiveGallery
        case about
        case personalInformation
        case onlinePresence
        case milestones
    }
    var readMoreIsEnabled: [CellType: Bool] = [:]
    
    var bottomSectionCells: [CellType] = [.about, .personalInformation, .onlinePresence, .milestones]
    var numberOfBottomSections: Int = 4
    var currentSegmentValue: Int = 0
    
    var editAction: ButtonAction?
    var readMoreAction: ButtonAction?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = PublicProfilePageViewModel(archiveData)
        
        getAllByArchiveNbr(archiveData)
        initUI()
        initButtonStates()
        initCollectionView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDataIsUpdated(_:)), name: .publicProfilePageUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initUI() {
        if let archiveName = viewModel?.archiveData?.fullName {
            title = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
        view.backgroundColor = .white
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        
        collectionView.register(ProfilePageArchiveCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier)
        collectionView.register(ProfilePageAboutCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier)
        collectionView.register(ProfilePagePersonInfoCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePagePersonInfoCollectionViewCell.identifier)
        collectionView.register(ProfilePageOnlinePresenceCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier)
        collectionView.register(ProfilePageMilestonesCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageMilestonesCollectionViewCell.identifier)
        
        collectionView.register(ProfilePageHeaderCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfilePageHeaderCollectionViewCell.identifier)
        collectionView.register(ProfilePageFooterCollectionViewCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfilePageFooterCollectionViewCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if currentSegmentValue == 0 {
            collectionView.reloadSections([1])
        } else {
            let bottomSectionsSet = IndexSet(integersIn: 1...4)
            collectionView.reloadSections(bottomSectionsSet)
        }
    }
    
    func initButtonStates() {
        readMoreIsEnabled[.about] = false
    }
    
    func getAllByArchiveNbr(_ archive: ArchiveVOData) {
        showSpinner()
        
        viewModel?.getAllByArchiveNbr(archive, { [self] error in
            hideSpinner()
            
            if error == nil {
                collectionView.performBatchUpdates {
                    collectionView.reloadSections([0])
                }
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    @objc func onDataIsUpdated(_ notification: Notification) {
        getAllByArchiveNbr(archiveData)
    }
}

// MARK: - UICollectionViewDataSource
extension PublicProfilePageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfBottomSections
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var sectionCellType: [PublicProfilePageViewController.CellType] = []
        sectionCellType = [bottomSectionCells[indexPath.section]]
        
        let currentCellType = sectionCellType[indexPath.item]
        let returnedCell: UICollectionViewCell
        
        switch currentCellType {
        case .archiveGallery:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier, for: indexPath) as! ProfilePageArchiveCollectionViewCell
            returnedCell = cell
            
        case .about:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier, for: indexPath) as! ProfilePageAboutCollectionViewCell
            
            let shortDescriptionValue = viewModel?.blurbProfileItem?.shortDescription
            let longDescriptionValue = viewModel?.descriptionProfileItem?.longDescription
            
            cell.configure(shortDescriptionValue, longDescriptionValue, viewModel?.archiveType)
            returnedCell = cell
            
        case .personalInformation:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePagePersonInfoCollectionViewCell.identifier, for: indexPath) as! ProfilePagePersonInfoCollectionViewCell
            
            let nicknameText = viewModel?.basicProfileItem?.nickname
            let fullNameText = viewModel?.basicProfileItem?.fullName
            let profileGenderText = viewModel?.profileGenderProfileItem?.personGender
            let birthDateText = viewModel?.birthInfoProfileItem?.birthDate
            let birthLocationText = viewModel?.birthInfoProfileItem?.birthLocationFormated

            cell.configure(fullName: fullNameText, nickname: nicknameText, gender: profileGenderText, birthDate: birthDateText, birthLocation: birthLocationText)

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
        var sectionCellType: [PublicProfilePageViewController.CellType] = []
        sectionCellType = [bottomSectionCells[indexPath.section]]
        
        let currentCellType = sectionCellType[indexPath.item]
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageHeaderCollectionViewCell.identifier, for: indexPath) as! ProfilePageHeaderCollectionViewCell
            switch currentCellType {
            case .archiveGallery:
                headerCell.configure(titleLabel: "Archive", buttonText: "Share")
                
            case .about:
                headerCell.configure(titleLabel: "About", buttonText: "Edit")
                
                headerCell.buttonAction = { [weak self] in
                    let profileAboutVC = UIViewController.create(withIdentifier: .profileAboutPage, from: .profile) as! PublicProfileAboutPageViewController
                    profileAboutVC.viewModel = self?.viewModel
                    
                    let navigationVC = NavigationController(rootViewController: profileAboutVC)
                    navigationVC.modalPresentationStyle = .fullScreen
                    self?.present(navigationVC, animated: true)
                }
                
            case .personalInformation:
                headerCell.configure(titleLabel: "Person Information", buttonText: "Edit")
                
                headerCell.buttonAction = { [weak self] in
                    let profilePernalInformationVC = UIViewController.create(withIdentifier: .profilePersonalInfoPage, from: .profile) as! PublicProfilePersonalInfoViewController
                    profilePernalInformationVC.viewModel = self?.viewModel
                    
                    let navigationVC = NavigationController(rootViewController: profilePernalInformationVC)
                    navigationVC.modalPresentationStyle = .fullScreen
                    self?.present(navigationVC, animated: true)
                }
                    
            case .onlinePresence:
                headerCell.configure(titleLabel: "Online Presence", buttonText: "Edit", buttonIsHidden: true)
                
            case .milestones:
                headerCell.configure(titleLabel: "Milestones", buttonText: "Edit", buttonIsHidden: true)
            }
            return headerCell
            
        case UICollectionView.elementKindSectionFooter:
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageFooterCollectionViewCell.identifier, for: indexPath) as! ProfilePageFooterCollectionViewCell
            switch currentCellType {
            case .archiveGallery:
                footerCell.configure(isReadMoreButtonHidden: true, isBottomLineHidden: true)
                
            case .personalInformation:
                footerCell.configure(isReadMoreButtonHidden: true)
                
            case .milestones:
                footerCell.configure(isReadMoreButtonHidden: true)
                
            case .about:
                footerCell.configure(isReadMoreButtonHidden: false, isBottomLineHidden: false, isReadMoreEnabled: self.readMoreIsEnabled[.about] ?? false)
                
                footerCell.readMoreButtonAction = { [weak self] in
                    if let readMoreForAbout = self?.readMoreIsEnabled[.about] {
                        self?.readMoreIsEnabled[.about] = !readMoreForAbout
                        footerCell.readMoreIsEnabled = !readMoreForAbout
                        collectionView.reloadSections([1])
                    }
                }
                
            case .onlinePresence:
                footerCell.configure(isReadMoreButtonHidden: false, isBottomLineHidden: false)
            }
            return footerCell
            
        default:
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PublicProfilePageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var sectionCellType: [PublicProfilePageViewController.CellType] = []
        sectionCellType = [bottomSectionCells[indexPath.section]]
        
        let currentCellType = sectionCellType[indexPath.item]
        
        switch currentCellType {
        case .about:
            let shortDescriptionValue: String = viewModel?.blurbProfileItem?.shortDescription ?? (viewModel?.archiveType.shortDescriptionHint)!
            let longDescriptionValue: String = viewModel?.descriptionProfileItem?.longDescription ?? (viewModel?.archiveType.longDescriptionHint)!
            
            var descriptionText = shortDescriptionValue

            if readMoreIsEnabled[.about] ?? false {
                descriptionText.append(contentsOf: "\n\n\(longDescriptionValue)")
            }
            
            let currentText: NSAttributedString = NSAttributedString(string: descriptionText, attributes: [NSAttributedString.Key.font: Text.style8.font as Any])
            let textHeight = currentText.boundingRect(with: CGSize(width: collectionView.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height.rounded(.up)
 
            return CGSize(width: UIScreen.main.bounds.width, height: textHeight + 20)
            
        case .personalInformation:
            return CGSize(width: UIScreen.main.bounds.width, height: 260)
            
        case .onlinePresence:
            return CGSize(width: UIScreen.main.bounds.width, height: 100)
            
        case .milestones:
            return CGSize(width: UIScreen.main.bounds.width, height: 130)
            
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
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate?.childVC(self, didScrollToOffset: scrollView.contentOffset) ?? false {
            scrollView.contentOffset = .zero
        }
    }
}
