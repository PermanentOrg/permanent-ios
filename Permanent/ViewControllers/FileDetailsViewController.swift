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
        case saveButton
        case uploaded
        case lastModified
        case created
        case fileCreated
        case size
        case fileType
        case originalFileName
        case originalFileType
    }
    
    var file: FileViewModel!
    let fileHelper = FileHelper()
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    
    let topSectionCells: [CellType] = [.thumbnail, .segmentedControl]
    var bottomSectionCells: [CellType] = [.name, .description, .date, .location, .tags, .saveButton]
    
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
        collectionView.register(SaveButtonCollectionViewCell.nib(), forCellWithReuseIdentifier: SaveButtonCollectionViewCell.identifier)
        collectionView.register(FileDetailsMapViewCellCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier)
        
        if viewModel == nil {
            viewModel = FilePreviewViewModel(file: file)
            viewModel?.getRecord(file: file, then: { record in
                self.title = record?.recordVO?.displayName
                self.collectionView.reloadData()
            })
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func initUI() {
        view.backgroundColor = .black
        styleNavBar()
    
        let rightButtonImage = UIBarButtonItem.SystemItem.action
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: rightButtonImage, target: self, action: #selector(shareButtonAction(_:)))
        
        title = file.name
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    func willClose() {
        
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

    private func saveButtonPressed(_ cell: SaveButtonCollectionViewCell) {
        let name = (collectionView.cellForItem(at: [1,0]) as? FileDetailsBottomCollectionViewCell)?.detailsTextField.text
        let description = (collectionView.cellForItem(at: [1,1]) as? FileDetailsBottomCollectionViewCell)?.detailsTextField.text
        let date = (collectionView.cellForItem(at: [1,2]) as? FileDetailsDateCollectionViewCell)?.date
        
        cell.isSaving = true
        viewModel?.update(file: file, name: name, description: description, date: date, location: nil, completion: { (success) in
            cell.isSaving = false
            
            if success {
                self.title = name
                self.collectionView.reloadSections([1])
                (self.navigationController as? FilePreviewNavigationController)?.hasChanges = true
            }
            print(success)
        })
    }
    
    private func segmentedControlChanged(_ cell: FileDetailsMenuCollectionViewCell) {
        if cell.segmentedControl.selectedSegmentIndex == 0 {
            bottomSectionCells = [.name, .description, .date, .location, .tags, .saveButton]
        } else {
            bottomSectionCells = [.uploaded, .lastModified, .created, .fileCreated, .size, .fileType, .originalFileName, .originalFileType]
        }

        collectionView.reloadSections([1])
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
        
        let returnedCell: UICollectionViewCell
        
        switch currentCellType {
        case .thumbnail:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsTopCollectionViewCell.identifier, for: indexPath) as! FileDetailsTopCollectionViewCell

            cell.configure(with: recordVO?.thumbURL2000 ?? "")
            
            returnedCell = cell
        case .segmentedControl:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier, for: indexPath) as! FileDetailsMenuCollectionViewCell
            cell.configure(leftMenuTitle: "Info".localized(), rightMenuTitle: "Details".localized())
            cell.segmentedControlAction = segmentedControlChanged
            
            returnedCell = cell
        case .name, .description:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell
            cell.configure(title: title(forCellType: currentCellType), details: stringCellDetails(cellType: currentCellType), isDetailsFieldEditable: viewModel?.isEditable ?? false)

            returnedCell = cell
        case .date:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsDateCollectionViewCell.identifier, for: indexPath) as! FileDetailsDateCollectionViewCell
            
            cell.configure(title: title(forCellType: currentCellType), date: dateCellDetails(cellType: currentCellType), isDetailsFieldEditable: viewModel?.isEditable ?? false)
            
            returnedCell = cell
        case .location:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier, for: indexPath) as! FileDetailsMapViewCellCollectionViewCell
            if getLocationDetails() == (0,0) {
                cell.configure(title: title(forCellType: currentCellType), details: stringCellDetails(cellType: currentCellType), isMapHidden: true, isDetailsFieldEditable: viewModel?.isEditable ?? false)
            } else {
                cell.configure(title: title(forCellType: currentCellType), details: stringCellDetails(cellType: currentCellType), isDetailsFieldEditable: viewModel?.isEditable ?? false)
                cell.setLocation(getLocationDetails().latitude,getLocationDetails().longitude)
            }
            returnedCell = cell
        case .tags:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell
            cell.configure(title: title(forCellType: currentCellType), details: stringCellDetails(cellType: currentCellType))

            returnedCell = cell
        case .saveButton:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SaveButtonCollectionViewCell.identifier, for: indexPath) as! SaveButtonCollectionViewCell
            cell.configure(title: .save)
            cell.action = saveButtonPressed
            returnedCell = cell
        case .size, .fileType, .originalFileName, .originalFileType:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell
            cell.configure(title: title(forCellType: currentCellType), details: stringCellDetails(cellType: currentCellType))

            returnedCell = cell
        case .uploaded, .lastModified, .created, .fileCreated:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsDateCollectionViewCell.identifier, for: indexPath) as! FileDetailsDateCollectionViewCell
            
            cell.configure(title: title(forCellType: currentCellType), date: dateCellDetails(cellType: currentCellType))
            
            returnedCell = cell
        }
        
        return returnedCell
    }
    
    func getLocationDetails() -> (latitude: Double, longitude: Double) {
        if let latitude = recordVO?.locnVO?.latitude,
           let longitude = recordVO?.locnVO?.longitude {
            return (latitude,longitude)
        } else {
            return (0,0)
        }
    }
    
    func stringCellDetails(cellType: CellType) -> String {
        let details: String
        switch cellType {
        case .name:
            details = recordVO?.displayName ?? ""
        case .description:
            details = recordVO?.recordVODescription ?? ""
        case .location:
            if let address = viewModel?.getAddressString([recordVO?.locnVO?.streetNumber, recordVO?.locnVO?.streetName, recordVO?.locnVO?.locality, recordVO?.locnVO?.country]) {
                    details = address
            } else {
                details = ""
            }
        case .tags:
            details = recordVO?.tagVOS?.map({ ($0.name ?? "") }).joined(separator: ", ") ?? "(none)"
        case .size:
            details = ByteCountFormatter.string(fromByteCount: Int64(recordVO?.size ?? 0), countStyle: .file)
        case .fileType:
            details = URL(string: recordVO?.type)?.pathExtension ?? ""
        case .originalFileName:
            details = URL(string: recordVO?.uploadFileName)?.deletingPathExtension().absoluteString ?? ""
        case .originalFileType:
            details = URL(string: recordVO?.uploadFileName?.uppercased())?.pathExtension ?? ""
        default:
            details = "-"
        }
        return details
    }
    
    func dateCellDetails(cellType: CellType) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let date: Date?
        switch cellType {
        case .uploaded:
            date = dateFormatter.date(from: recordVO?.createdDT ?? "")
        case .lastModified:
            date = dateFormatter.date(from: recordVO?.updatedDT ?? "")
        case .date:
            date = dateFormatter.date(from: recordVO?.displayDT ?? "")
        case .created:
            date = dateFormatter.date(from: recordVO?.derivedDT ?? "")
        case .fileCreated:
            date = dateFormatter.date(from: recordVO?.derivedCreatedDT ?? "")
        default:
            date = nil
        }
        
        return date
    }
    
    func title(forCellType cellType: CellType) -> String {
        switch cellType {
        case .thumbnail:
            return ""
        case .segmentedControl:
            return ""
        case .name:
            return "Name".localized()
        case .description:
            return "Description".localized()
        case .date:
            return "Date".localized()
        case .location:
            return "Location".localized()
        case .tags:
            return "Tags".localized()
        case .saveButton:
            return ""
        case .uploaded:
            return "Uploaded".localized()
        case .lastModified:
            return "Last Modified".localized()
        case .created:
            return "Created".localized()
        case .fileCreated:
            return "File Created".localized()
        case .size:
            return "Size".localized()
        case .fileType:
            return "File Type".localized()
        case .originalFileName:
            return "Original File Name".localized()
        case .originalFileType:
            return "Original File Type".localized()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        if currentCellType == .thumbnail {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
            fileDetailsVC.file = file
            fileDetailsVC.viewModel = viewModel
            
            navigationController?.setViewControllers([fileDetailsVC], animated: false)
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
//TODO: present tag viewcontroller
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
        case .saveButton:
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case .location:
            if getLocationDetails() == (0,0) {
                return CGSize(width: UIScreen.main.bounds.width, height: 65)
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.65)
            }
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
