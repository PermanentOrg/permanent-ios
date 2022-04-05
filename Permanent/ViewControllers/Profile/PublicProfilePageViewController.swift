//
//  PublicProfilePageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

enum ProfileCellType {
    case profileVisibility
    case blurb
    case longDescription
    case fullName
    case nickName
    case gender
    case birthDate
    case birthLocation
    case onlinePresenceEmail
    case onlinePresenceLink
    case establishedDate
    case establishedLocation
    case milestone
    case archiveGallery
}

class PublicProfilePageViewController: BaseViewController<PublicProfilePageViewModel> {
    var archiveData: ArchiveVOData!
    weak var delegate: PublicArchiveChildDelegate?
    var profileData: [ProfileItemVO] = []
    
    enum ProfileSection: Int {
        case profileVisibility = 0
        case about = 1
        case information = 2
        case onlinePresenceEmail = 3
        case onlinePresenceLink = 4
        case milestones = 5
        case archiveGallery = 6
    }
    
    var readMoreIsEnabled: [ProfileSection: Bool] = [:]
    private var profileViewData: [ProfileSection: [ProfileCellType]] = [:]

    var currentSegmentValue: Int = 0
    
    var editAction: ButtonAction?
    var readMoreAction: ButtonAction?
    var isEditDataEnabled = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = PublicProfilePageViewModel(archiveData)
        
        getAllByArchiveNbr(archiveData)
        initUI()
        initButtonStates()
        initCollectionView()
        
        NotificationCenter.default.addObserver(forName: PublicProfilePageViewModel.profileItemsUpdatedNotificationName, object: nil, queue: nil) { [weak self] notification in
            self?.refreshProfileViewData()
            self?.collectionView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initUI() {
        if let archiveName = viewModel?.archiveData?.fullName {
            title = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
        view.backgroundColor = .white
        
        guard let isEditDataEnabled = viewModel?.isEditDataEnabled else { return }
        self.isEditDataEnabled = isEditDataEnabled
        
        refreshProfileViewData()
    }
    
    func initCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        
        collectionView.register(ProfilePageArchiveCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier)
        collectionView.register(ProfilePageAboutCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier)
        collectionView.register(ProfilePageInformationCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier)
        collectionView.register(ProfilePageOnlinePresenceCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier)
        collectionView.register(ProfilePageMilestonesCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageMilestonesCollectionViewCell.identifier)
        collectionView.register(ProfilePageVisibilityCollectionViewCell.nib(), forCellWithReuseIdentifier: ProfilePageVisibilityCollectionViewCell.identifier)

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
        readMoreIsEnabled[.onlinePresenceEmail] = false
    }
    
    func getAllByArchiveNbr(_ archive: ArchiveVOData) {
        showSpinner()
        
        viewModel?.getAllByArchiveNbr(archive, { [self] error in
            hideSpinner()
            
            if error == nil {
                refreshProfileViewData()
                
                collectionView.reloadData()
            } else {
                showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    func refreshProfileViewData() {
        profileViewData = [
            ProfileSection.about: [
            ],
            ProfileSection.information: [
                ProfileCellType.fullName,
                ProfileCellType.nickName
            ],
            ProfileSection.onlinePresenceEmail: [
            ],
            ProfileSection.milestones: [
            ]
        ]
        
        if isEditDataEnabled {
            profileViewData[ProfileSection.profileVisibility] = [ ProfileCellType.profileVisibility ]
        }
        
        guard let archiveType = viewModel?.archiveType else { return }
        switch archiveType {
        case .person:
            profileViewData[ProfileSection.information]?.append(contentsOf: [
                ProfileCellType.gender,
                ProfileCellType.birthDate,
                ProfileCellType.birthLocation
            ])
            
        case .family, .organization:
            profileViewData[ProfileSection.information]?.append(contentsOf: [
                ProfileCellType.establishedDate,
                ProfileCellType.establishedLocation
            ])
        }
        
        var aboutCells = [ProfileCellType]()
        if viewModel?.blurbProfileItem?.shortDescription?.isNotEmpty ?? false {
            aboutCells.append(.blurb)
        }
        if viewModel?.descriptionProfileItem?.longDescription?.isNotEmpty ?? false {
            aboutCells.append(.longDescription)
        }
        profileViewData[.about] = isEditDataEnabled ? [ProfileCellType.blurb, ProfileCellType.longDescription] : aboutCells
        
        profileViewData[.onlinePresenceEmail] = viewModel?.emailProfileItems.map({ _ in .onlinePresenceEmail }) ?? []
        profileViewData[.onlinePresenceLink] = viewModel?.socialMediaProfileItems.map({ _ in .onlinePresenceLink }) ?? []
        
        profileViewData[.milestones] = viewModel?.milestonesProfileItems.map({ _ in .milestone }) ?? []
    }
}

// MARK: - UICollectionViewDataSource
extension PublicProfilePageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSection = sections[section]
        
        switch currentSection {
        case .about:
            return (readMoreIsEnabled[.about] ?? false) ? profileViewData[.about]!.count : min(profileViewData[.about]!.count, 1)
            
        case .onlinePresenceEmail:
            let rowCount = profileViewData[currentSection]?.count ?? 0
            return (readMoreIsEnabled[.onlinePresenceEmail] ?? false) ? rowCount : min(2, rowCount)
            
        case .onlinePresenceLink:
            let rowCount = profileViewData[currentSection]?.count ?? 0
            return (readMoreIsEnabled[.onlinePresenceEmail] ?? false) ? rowCount : min(1, rowCount)
            
        case .milestones:
            let rowCount = profileViewData[currentSection]?.count ?? 0
            return rowCount
            
        default:
            return profileViewData[currentSection]?.count ?? 1
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return profileViewData.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = profileViewData[sections[indexPath.section]]![indexPath.row]

        let returnedCell: UICollectionViewCell
        
        switch currentCellType {
        case .archiveGallery:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageArchiveCollectionViewCell.identifier, for: indexPath) as! ProfilePageArchiveCollectionViewCell
            returnedCell = cell
            
        case .profileVisibility:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageVisibilityCollectionViewCell.identifier, for: indexPath) as! ProfilePageVisibilityCollectionViewCell
            cell.isPublicSwitch.isOn = viewModel?.isPubliclyVisible ?? false
            cell.switchAction = { [weak self] cell in
                guard let viewModel = self?.viewModel else { return }
                
                cell.isPublicSwitch.isEnabled = false
                
                viewModel.isPubliclyVisible.toggle()
                viewModel.updateProfileVisibility(isVisible: viewModel.isPubliclyVisible, completion: { status in
                    cell.isPublicSwitch.isEnabled = true
                    
                    // This view is part of a container view. banners have to be presented on the parent.
                    if status == .success {
                        self?.parent?.view.showNotificationBanner(title: "Successfully updated profile visibility".localized())
                    } else {
                        self?.parent?.view.showNotificationBanner(title: "Failed to update profile visibility".localized(), backgroundColor: .deepRed)
                    }
                })
            }
            returnedCell = cell
            
        case .blurb:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier, for: indexPath) as! ProfilePageAboutCollectionViewCell
            let shortDescriptionValue = viewModel?.blurbProfileItem?.shortDescription
            
            if isEditDataEnabled {
                cell.configure(shortDescriptionValue ?? viewModel?.archiveType.shortDescriptionHint)
            } else {
                cell.configure(shortDescriptionValue)
            }
            returnedCell = cell
            
        case .longDescription:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageAboutCollectionViewCell.identifier, for: indexPath) as! ProfilePageAboutCollectionViewCell
            let longDescriptionValue = viewModel?.descriptionProfileItem?.longDescription
            
            if isEditDataEnabled {
                cell.configure(longDescriptionValue ?? viewModel?.archiveType.longDescriptionHint)
            } else {
                cell.configure(longDescriptionValue)
            }
            returnedCell = cell
            
        case .fullName:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let fullNameText = viewModel?.basicProfileItem?.fullName
    
            cell.configure(with: fullNameText, archiveType: viewModel?.archiveType, cellType: currentCellType, isEditDataEnabled: isEditDataEnabled)

            returnedCell = cell
            
        case .nickName:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let nicknameText = viewModel?.basicProfileItem?.nickname
            
            cell.configure(with: nicknameText, archiveType: viewModel?.archiveType, cellType: currentCellType, isEditDataEnabled: isEditDataEnabled)

            returnedCell = cell
            
        case .gender:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let profileGenderText = viewModel?.profileGenderProfileItem?.personGender
            
            cell.configure(with: profileGenderText, archiveType: viewModel?.archiveType, cellType: currentCellType, isEditDataEnabled: isEditDataEnabled)
            returnedCell = cell
            
        case .birthDate:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let birthDateText = viewModel?.birthInfoProfileItem?.birthDate
            
            cell.configure(with: birthDateText, archiveType: viewModel?.archiveType, cellType: currentCellType, isEditDataEnabled: isEditDataEnabled)
            returnedCell = cell
            
        case .birthLocation:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let birthLocationText = viewModel?.birthInfoProfileItem?.birthLocationFormated
            
            cell.configure(with: birthLocationText, archiveType: viewModel?.archiveType, cellType: currentCellType, isEditDataEnabled: isEditDataEnabled)
            returnedCell = cell
            
        case .onlinePresenceEmail:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier, for: indexPath) as! ProfilePageOnlinePresenceCollectionViewCell
            
            cell.configure(link: viewModel?.emailProfileItems[indexPath.row].email)
            returnedCell = cell
            
        case .onlinePresenceLink:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageOnlinePresenceCollectionViewCell.identifier, for: indexPath) as! ProfilePageOnlinePresenceCollectionViewCell
            
            cell.configure(link: viewModel?.socialMediaProfileItems[indexPath.row].link)
            returnedCell = cell
            
        case .establishedDate:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let dateText = viewModel?.establishedInfoProfileItem?.establishedDate
            
            cell.configure(with: dateText, archiveType: viewModel?.archiveType, cellType: currentCellType)
            returnedCell = cell
            
        case .establishedLocation:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageInformationCollectionViewCell.identifier, for: indexPath) as! ProfilePageInformationCollectionViewCell
            let locationText = viewModel?.establishedInfoProfileItem?.establishedLocationFormated
            
            cell.configure(with: locationText, archiveType: viewModel?.archiveType, cellType: currentCellType)
            returnedCell = cell
            
        case .milestone:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfilePageMilestonesCollectionViewCell.identifier, for: indexPath) as! ProfilePageMilestonesCollectionViewCell
            
            cell.configure(milestone: viewModel?.milestonesProfileItems[indexPath.row])
            returnedCell = cell
        }
        
        return returnedCell
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSectionType = sections[indexPath.section]
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageHeaderCollectionViewCell.identifier, for: indexPath) as! ProfilePageHeaderCollectionViewCell
            switch currentSectionType {
            case .profileVisibility:
                headerCell.configure(titleLabel: "Profile Visibility".localized(), buttonText: "")
                
            case .archiveGallery:
                headerCell.configure(titleLabel: "Archive", buttonText: "Share")
                
            case .about:
                headerCell.configure(titleLabel: "About".localized(), buttonText: "Edit".localized(), buttonIsHidden: !isEditDataEnabled)
                
                headerCell.buttonAction = { [weak self] in
                    let profileAboutVC = UIViewController.create(withIdentifier: .profileAboutPage, from: .profile) as! PublicProfileAboutPageViewController
                    profileAboutVC.viewModel = self?.viewModel

                    let navigationVC = NavigationController(rootViewController: profileAboutVC)
                    self?.present(navigationVC, animated: true)
                }
                
            case .information:
                if let title = viewModel?.archiveType.personalInformationPublicPageTitle {
                    headerCell.configure(titleLabel: title, buttonText: "Edit".localized(), buttonIsHidden: !isEditDataEnabled)
                }
                
                headerCell.buttonAction = { [weak self] in
                    let profilePernalInformationVC = UIViewController.create(withIdentifier: .profilePersonalInfoPage, from: .profile) as! PublicProfilePersonalInfoViewController
                    profilePernalInformationVC.viewModel = self?.viewModel
                    
                    let navigationVC = NavigationController(rootViewController: profilePernalInformationVC)
                    self?.present(navigationVC, animated: true)
                }
                    
            case .onlinePresenceEmail:
                headerCell.configure(titleLabel: "Online Presence".localized(), buttonText: "Edit".localized(), buttonIsHidden: !isEditDataEnabled)
                
                headerCell.buttonAction = { [weak self] in
                    let vc = UIViewController.create(withIdentifier: .onlinePresence, from: .profile) as! PublicProfileOnlinePresenceViewController
                    vc.viewModel = self?.viewModel
                    
                    let navigationVC = NavigationController(rootViewController: vc)
                    self?.present(navigationVC, animated: true)
                }
                
            case .onlinePresenceLink:
                return UICollectionReusableView()
                
            case .milestones:
                headerCell.configure(titleLabel: "Milestones".localized(), buttonText: "Edit".localized(), buttonIsHidden: !isEditDataEnabled)
                
                headerCell.buttonAction = { [weak self] in
                    let vc = UIViewController.create(withIdentifier: .milestones, from: .profile) as! PublicProfileMilestonesViewController
                    vc.viewModel = self?.viewModel
                    
                    let navigationVC = NavigationController(rootViewController: vc)
                    self?.present(navigationVC, animated: true)
                }
            }
            
            return headerCell
            
        case UICollectionView.elementKindSectionFooter:
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfilePageFooterCollectionViewCell.identifier, for: indexPath) as! ProfilePageFooterCollectionViewCell
            switch currentSectionType {
            case .archiveGallery:
                footerCell.configure(isReadMoreButtonHidden: true, isBottomLineHidden: true)
                
            case .profileVisibility:
                footerCell.configure(isReadMoreButtonHidden: true, isBottomLineHidden: !isEditDataEnabled)
                
            case .information:
                footerCell.configure(isReadMoreButtonHidden: true)
                
            case .milestones:
                footerCell.configure(isReadMoreButtonHidden: true)
                
            case .about:
                footerCell.configure(isReadMoreButtonHidden: profileViewData[.about]!.count <= 1, isBottomLineHidden: false, isReadMoreEnabled: readMoreIsEnabled[.about] ?? false)
                
                footerCell.readMoreButtonAction = { [weak self] in
                    if let readMore = self?.readMoreIsEnabled[.about] {
                        self?.readMoreIsEnabled[.about] = !readMore
                        footerCell.readMoreIsEnabled = !readMore
                        
                        let sectionIdx = Int(sections.firstIndex(of: .about) ?? 0)
                        collectionView.reloadSections([sectionIdx])
                    }
                }
                
            case .onlinePresenceLink:
                footerCell.configure(isReadMoreButtonHidden: false, isBottomLineHidden: false, isReadMoreEnabled: readMoreIsEnabled[.onlinePresenceEmail] ?? false)
                
                footerCell.readMoreButtonAction = { [weak self] in
                    if let readMore = self?.readMoreIsEnabled[.onlinePresenceEmail] {
                        self?.readMoreIsEnabled[.onlinePresenceEmail] = !readMore
                        footerCell.readMoreIsEnabled = !readMore
                        
                        let emailSectionIdx = Int(sections.firstIndex(of: .onlinePresenceEmail) ?? 0)
                        let linkSectionIdx = Int(sections.firstIndex(of: .onlinePresenceLink) ?? 0)
                        collectionView.reloadSections([emailSectionIdx, linkSectionIdx])
                    }
                }
                
            default:
                return UICollectionReusableView()
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
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = profileViewData[sections[indexPath.section]]![indexPath.row]
        
        switch currentCellType {
        case .profileVisibility:
            return CGSize(width: UIScreen.main.bounds.width, height: 80)
            
        case .blurb:
            let text = viewModel?.blurbProfileItem?.shortDescription ?? (viewModel?.archiveType.shortDescriptionHint)!
            return ProfilePageAboutCollectionViewCell.size(withText: text, collectionView: collectionView)
            
        case .longDescription:
            let text = viewModel?.descriptionProfileItem?.longDescription ?? (viewModel?.archiveType.longDescriptionHint)!
            return ProfilePageAboutCollectionViewCell.size(withText: text, collectionView: collectionView)

        case .fullName, .nickName, .gender, .birthDate, .birthLocation, .establishedDate, .establishedLocation:
            return ProfilePageInformationCollectionViewCell.size(collectionView: collectionView)

        case .onlinePresenceLink, .onlinePresenceEmail:
            return ProfilePageOnlinePresenceCollectionViewCell.size(collectionView: collectionView)

        case .milestone:
            return ProfilePageMilestonesCollectionViewCell.size(collectionView: collectionView)

        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 120)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentCellType = profileViewData[sections[indexPath.section]]![indexPath.row]
        
        guard let viewModel = viewModel else { return }
        
        switch currentCellType {
        case .onlinePresenceLink:
            let item = viewModel.socialMediaProfileItems[indexPath.row]
            
            if let url = URL(string: item.link), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case .onlinePresenceEmail:
            let item = viewModel.emailProfileItems[indexPath.row]
            
            if let emailString = item.email, let url = URL(string: "mailto:" + emailString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSectionType = sections[section]
        
        switch currentSectionType {
        case .onlinePresenceEmail:
            return UIEdgeInsets.zero
            
        default:
            return UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSectionType = sections[section]
        
        switch currentSectionType {
        case .onlinePresenceLink:
            return CGSize.zero
            
        default:
            return CGSize(width: collectionView.frame.width, height: 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let sections = Array(profileViewData.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let currentSectionType = sections[section]
        
        switch currentSectionType {
        case .about:
            return profileViewData[.about]!.count <= 1 ? CGSize(width: collectionView.frame.width, height: 1) : CGSize(width: collectionView.frame.width, height: 40)
            
        case .onlinePresenceEmail:
            return CGSize.zero
            
        case .information, .profileVisibility:
            return CGSize(width: collectionView.frame.width, height: 1)
            
        default:
            return CGSize(width: collectionView.frame.width, height: 40)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate?.childVC(self, didScrollToOffset: scrollView.contentOffset) ?? false {
            scrollView.contentOffset = .zero
        }
    }
}
