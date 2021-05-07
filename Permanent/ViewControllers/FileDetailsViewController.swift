//
//  FileDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.03.2021.
//

import UIKit

class FileDetailsViewController: BaseViewController<FilePreviewViewModel> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? [.portrait] : [.all]
    }
    
    enum CellType {
        case thumbnail
        case segmentedControl
        case name
        case description
        case date
        case location
        case tags
        case uploaded
        case lastModified
        case created
        case fileCreated
        case size
        case fileType
        case originalFileName
        case originalFileType
    }
    
    weak var delegate: FilePreviewNavigationControllerDelegate?
    
    var file: FileViewModel!
    let fileHelper = FileHelper()
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    
    let topSectionCells: [CellType] = [.thumbnail, .segmentedControl]
    var bottomSectionCells: [CellType] = [.name, .description, .date, .location, .tags]
    
    let documentInteractionController = UIDocumentInteractionController()
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .black

        collectionView.register(FileDetailsTopCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsTopCollectionViewCell.identifier)
        collectionView.register(FileDetailsMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier)
        collectionView.register(FileDetailsBottomCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier)
        collectionView.register(FileDetailsDateCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsDateCollectionViewCell.identifier)
        collectionView.register(FileDetailsMapViewCellCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier)
        collectionView.register(TagsNamesCollectionViewCell.nib(), forCellWithReuseIdentifier: TagsNamesCollectionViewCell.identifier)
        
        if viewModel == nil {
            viewModel = FilePreviewViewModel(file: file)
            viewModel?.getRecord(file: file, then: { record in
                self.title = record?.recordVO?.displayName
                self.collectionView.reloadData()
            })
            
            title = file.name
        } else {
            title = viewModel!.recordVO?.recordVO?.displayName
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateData(_:)), name: .filePreviewVMDidSaveData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFailedUpdateData(_:)), name: .filePreviewVMSaveDataFailed, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func initUI() {
        view.backgroundColor = .black
        styleNavBar()
        
        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
    
        let rightButtonImage = UIBarButtonItem.SystemItem.action
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: rightButtonImage, target: self, action: #selector(shareButtonAction(_:)))
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    @objc private func shareButtonAction(_ sender: Any) {
        if let fileName = viewModel?.fileName(),
           let localURL = fileHelper.url(forFileNamed: fileName)
        {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            }))
            
            present(preparingAlert, animated: true) {
                if let record = self.viewModel?.recordVO {
                    self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { url, _ in
                        if let url = url {
                            self.dismiss(animated: true) {
                                self.share(url: url)
                            }
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: false) {
            self.delegate?.filePreviewNavigationControllerWillClose(self, hasChanges: (self.navigationController as? FilePreviewNavigationController)?.hasChanges ?? false)
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let collectionView = collectionView,
              let keyBoardInfo = notification.userInfo,
              let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let window = collectionView.window
        else { return }
        
        let keyBoardFrame = window.convert(endFrame.cgRectValue, to: collectionView.superview)
        let newBottomInset = collectionView.frame.origin.y + collectionView.frame.size.height - keyBoardFrame.origin.y
        var tableInsets = collectionView.contentInset
        var scrollIndicatorInsets = collectionView.scrollIndicatorInsets
        let oldBottomInset = tableInsets.bottom
        if newBottomInset > oldBottomInset {
            tableInsets.bottom = newBottomInset
            scrollIndicatorInsets.bottom = tableInsets.bottom
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
            collectionView.contentInset = tableInsets
            collectionView.scrollIndicatorInsets = scrollIndicatorInsets
            UIView.commitAnimations()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        var tableInsets = collectionView.contentInset
        var scrollIndicatorInsets = collectionView.scrollIndicatorInsets
        tableInsets.bottom = 0
        scrollIndicatorInsets.bottom = tableInsets.bottom
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        collectionView.contentInset = tableInsets
        collectionView.scrollIndicatorInsets = scrollIndicatorInsets
        UIView.commitAnimations()
    }

    private func share(url: URL) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        documentInteractionController.dismissMenu(animated: true)
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
    }
    
    private func segmentedControlChangedAction() -> ((FileDetailsMenuCollectionViewCell) -> Void) {
        return { [weak self] cell in
            guard let strongSelf = self else { return }
            
            if cell.segmentedControl.selectedSegmentIndex == 0 {
                strongSelf.bottomSectionCells = [.name, .description, .date, .location, .tags]
            } else {
                strongSelf.bottomSectionCells = [.uploaded, .lastModified, .created, .fileCreated, .size, .fileType, .originalFileName, .originalFileType]
            }
            
            strongSelf.collectionView.reloadSections([1])
        }
    }
    
    @objc func onDidUpdateData(_ notification: Notification) {
        if let notifVM = notification.object as? FilePreviewViewModel, notifVM.file == viewModel?.file {
            self.title = viewModel?.name
            collectionView.reloadSections([1])
            view.showNotificationBanner(title: "Change was saved".localized())
        }
    }
    
    @objc func onFailedUpdateData(_ notification: Notification) {
        if let notifVM = notification.object as? FilePreviewViewModel, notifVM.file == viewModel?.file {
            view.showNotificationBanner(title: "Failed to save changes".localized(), backgroundColor: .deepRed)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension FileDetailsViewController: UICollectionViewDataSource {
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
        
        let returnedCell: FileDetailsBaseCollectionViewCell
        
        switch currentCellType {
        case .thumbnail:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsTopCollectionViewCell.identifier, for: indexPath) as! FileDetailsTopCollectionViewCell
            
            returnedCell = cell
            
        case .segmentedControl:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier, for: indexPath) as! FileDetailsMenuCollectionViewCell
            cell.segmentedControlAction = segmentedControlChangedAction()
            
            returnedCell = cell
            
        case .name, .description, .size, .fileType, .originalFileName, .originalFileType:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell

            returnedCell = cell

        case .location:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier, for: indexPath) as! FileDetailsMapViewCellCollectionViewCell
            
            returnedCell = cell
        case .tags:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagsNamesCollectionViewCell.identifier, for: indexPath) as! TagsNamesCollectionViewCell
            
            returnedCell = cell
        case .date, .uploaded, .lastModified, .created, .fileCreated:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsDateCollectionViewCell.identifier, for: indexPath) as! FileDetailsDateCollectionViewCell
            
            returnedCell = cell
        }
        
        returnedCell.configure(withViewModel: viewModel!, type: currentCellType)
        
        return returnedCell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        if currentCellType == .thumbnail {
            dismiss(animated: false, completion: nil)
        }
        
        if currentCellType == .location && viewModel?.isEditable ?? false {
            let locationSetVC = UIViewController.create(withIdentifier: .locationSetOnTap, from: .main) as! LocationSetViewController
            locationSetVC.delegate = self
            locationSetVC.file = file
            locationSetVC.viewModel = viewModel
            
            let navigationVC = NavigationController(rootViewController: locationSetVC)
            navigationVC.modalPresentationStyle = .fullScreen
            present(navigationVC, animated: true)
        }
        
        if currentCellType == .tags && viewModel?.isEditable ?? false {
            let tagSetVC = UIViewController.create(withIdentifier: .tagDetails, from: .main) as! TagDetailsViewController
            tagSetVC.delegate = self
            tagSetVC.viewModel = viewModel

            let navigationVC = NavigationController(rootViewController: tagSetVC)
            navigationVC.modalPresentationStyle = .fullScreen
            present(navigationVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        switch currentCellType {
        case .thumbnail:
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
        case .segmentedControl:
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case .location:
            if let _ = viewModel?.recordVO?.recordVO?.locnVO?.latitude,
               let _ = viewModel?.recordVO?.recordVO?.locnVO?.longitude {
                return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.65)
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: 65)
            }
        case .tags:
            let cellHeight: CGFloat = 40
            let countTags = viewModel?.recordVO?.recordVO?.tagVOS?.count ?? 0
            //Logic for cell height: for being able to show only 2.5 lines when there are more then 3 tags associated to current file
            let cellHeightByTagsNumber :CGFloat = CGFloat(( countTags > 3 ) ? ( (cellHeight * 3) + 13 ) : ( cellHeight * 2 ))
            return CGSize(width: UIScreen.main.bounds.width, height: cellHeightByTagsNumber)
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
        return UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0)
    }
}

// MARK: - LocationSetViewControllerDelegate
extension FileDetailsViewController: LocationSetViewControllerDelegate {
    func locationSetViewControllerDidUpdate(_ locationVC: LocationSetViewController) {
        collectionView.reloadSections([1])
    }
}

// MARK: - TagDetailsViewControllerDelegate
extension FileDetailsViewController: TagDetailsViewControllerDelegate {
    func tagDetailsViewControllerDidUpdate(_ tagVC: TagDetailsViewController) {
        collectionView.reloadSections([1])
    }
}
