//
//  FileDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.03.2021.
//

import UIKit

class FileDetailsViewController: BaseViewController<FilePreviewViewModel> {
    var file: FileViewModel!
    let fileHelper = FileHelper()
    var recordVO: RecordVOData!
    let infoSubmenuItems: [String] = ["Name", "Description", "Date", "Location", "Tags"]
    let detailsSubmenuItems: [String] = ["Uploaded", "Last Modified", "Created", "File Created", "Size", "File Type", "Original File Name:", "Original File Type"]
    
    let documentInteractionController = UIDocumentInteractionController()
    
    var infoDetailsCellNumber: [Int]!
    var currentSubmenuSelection = 0
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showSpinner()
        initUI()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .black

        collectionView.register(FileDetailsTopCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsTopCollectionViewCell.identifier)
        collectionView.register(FileDetailsMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier)
        collectionView.register(FileDetailsBottomCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier)
        collectionView.register(SaveButtonCollectionViewCell.nib(), forCellWithReuseIdentifier: SaveButtonCollectionViewCell.identifier)
        
        viewModel = FilePreviewViewModel(file: file)
        viewModel?.getRecord(file: file, then: { record in
            self.recordVO = record?.recordVO

            self.collectionView.delegate = self
            self.collectionView.dataSource = self
        })

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

        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.title = file.name
        
        infoDetailsCellNumber = [infoSubmenuItems.count + 1, detailsSubmenuItems.count]
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    @objc private func closeButtonAction(_ sender: Any) {
        updateSpinner(isLoading: false)
        dismiss(animated: true, completion: nil)
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
    
    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
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
}

extension FileDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return infoDetailsCellNumber[currentSubmenuSelection]
        }
        return 2
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsTopCollectionViewCell.identifier, for: indexPath) as! FileDetailsTopCollectionViewCell

                cell1.configure(with: recordVO.thumbURL2000 ?? "")
                cell1.imageLoadedCallback = { [weak self] _ in
                    self?.hideSpinner()
                }
                return cell1
            } else {
                let cell2 = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier, for: indexPath) as! FileDetailsMenuCollectionViewCell
                cell2.configure(leftMenuTitle: "Info", rightMenuTitle: "Details")
                cell2.segmentedControlAction = { _ in
                    self.currentSubmenuSelection = cell2.segmentedControl.selectedSegmentIndex
                    let indexSet = IndexSet(integer: indexPath[1])
                    self.collectionView.reloadSections(indexSet)
                }
                
                return cell2
            }
        } else {
            if indexPath.item < 5 || currentSubmenuSelection == 1 {
                let cell3 = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell
                if currentSubmenuSelection == 0 && indexPath.item < 3 {
                    if indexPath.item == 2 {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        let date = dateFormatter.date(from: recordVO.displayDT ?? "")
                        cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item), isDetailsFieldEditable: true, isDatePicker: true, date: date)
                    } else {
                        cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item), isDetailsFieldEditable: true)
                    }
                } else {
                    cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item))
                }
                return cell3
            } else {
                let cell4 = collectionView.dequeueReusableCell(withReuseIdentifier: SaveButtonCollectionViewCell.identifier, for: indexPath) as! SaveButtonCollectionViewCell
                cell4.configure(title: .save)
                cell4.action = { [weak self] cell in
                    guard let file = self?.file else { return }
                    
                    let name = (self?.collectionView.cellForItem(at: [1,0]) as? FileDetailsBottomCollectionViewCell)?.detailsTextField.text
                    let description = (self?.collectionView.cellForItem(at: [1,1]) as? FileDetailsBottomCollectionViewCell)?.detailsTextField.text
                    let date = (self?.collectionView.cellForItem(at: [1,2]) as? FileDetailsBottomCollectionViewCell)?.date
                    
                    cell.isSaving = true
                    self?.viewModel?.update(file: file, name: name, description: description, date: date, completion: { (success) in
                        cell.isSaving = false
                        
                        if success, let strongSelf = self {
                            strongSelf.file.name = name ?? ""
                            strongSelf.file.description = description ?? ""
                            strongSelf.title = name
                        }
                        print(success)
                    })
                }
                return cell4
            }
        }
    }
    
    func cellTitle(itemNumber: Int) -> String {
        if currentSubmenuSelection == 0 {
            return infoSubmenuItems[itemNumber]
        }
        return detailsSubmenuItems[itemNumber]
    }
    
    func cellDetails(itemNumber: Int) -> String {
        var details: String!
        switch (itemNumber, currentSubmenuSelection) {
        case (0, 0):
            details = recordVO.displayName
        case (0, 1):
            details = convertDateFormater(recordVO.createdDT ?? "-")
        case (1, 0):
            details = recordVO.recordVODescription ?? ""
        case (1, 1):
            details = convertDateFormater(recordVO.updatedDT ?? "-")
        case (2, 0):
            details = convertDateFormater(recordVO.displayDT ?? "")
        case (2, 1):
            details = convertDateFormater(recordVO.derivedDT ?? "-")
        case (3, 0):
            if
                let country = recordVO.locnVO?.country
            {
                details = "\(country)"
            } else {
                details = "(none)"
            }
        case (3, 1):
            details = convertDateFormater(recordVO.derivedCreatedDT ?? "-")
        case (4, 0):
            details = ""
            if recordVO.tagVOS?.count != 0 {
                recordVO.tagVOS?.forEach { element in
                    if let name = element.name {
                        details += name + " "
                    }
                }
            } else {
                details = "(none)"
            }
        case (4, 1):
            details = ByteCountFormatter.string(fromByteCount: Int64(recordVO.size ?? 0), countStyle: .file)
        case (5, _):
            details = URL(string: recordVO.type)?.pathExtension
        case (6, _):
            details = URL(string: recordVO.uploadFileName)?.deletingPathExtension().absoluteString
        case (7, _):
            details = URL(string: recordVO.uploadFileName?.uppercased())?.pathExtension
        case (8, _):
            details = "-"
        default:
            details = "-"
        }
        return details
    }
    
    func convertDateFormater(_ date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let dateProcessed = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
            if currentSubmenuSelection == 0 {
                return dateFormatter.string(from: dateProcessed) + " GMT"
            } else {
                return dateFormatter.string(from: dateProcessed)
            }
        } else {
            return ""
        }
    }
}

extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath == [0, 0] {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
            fileDetailsVC.file = file
            
            navigationController?.setViewControllers([fileDetailsVC], animated: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (indexPath.section, indexPath.row, currentSubmenuSelection) {
        case (0, 0, _):
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
        case (0, 1, _):
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case (1, 5, 0):
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case (1, _, _):
            return CGSize(width: UIScreen.main.bounds.width, height: 65)
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 10)
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

extension FileDetailsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}
