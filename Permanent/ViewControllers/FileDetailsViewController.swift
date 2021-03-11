//
//  FileDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.03.2021.
//

import UIKit

let reuseIdentifier = "CellIdentifer";

class FileDetailsViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var recordVO: RecordVOData!
    let infoSubmenuItems: [String] = ["Name", "Description", "Date", "Location", "Tags"]
    let detailsSubmenuItems: [String] = ["Uploaded", "Uploaded By","Last Modified","Created","File Created","Size","File Type","Original File Name:","Original File Type"]
    var infoDetailsCellNumber: [Int]!
    var currentSubmenuSelection = 0
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSpinner()
        self.initUI()

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
                self.hideSpinner()

        

            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            
        })

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSpinner(isLoading: true)
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
        
        infoDetailsCellNumber = [infoSubmenuItems.count + 1,detailsSubmenuItems.count]
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
        updateSpinner(isLoading: false)
        dismiss(animated: true, completion: nil)
    }
    
    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
    }
}

extension FileDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1
        {
           return infoDetailsCellNumber[currentSubmenuSelection]
        }
        return 2
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
       // let cell: UICollectionViewCell!
        
        updateSpinner(isLoading: false)
        
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsTopCollectionViewCell.identifier, for: indexPath) as! FileDetailsTopCollectionViewCell
                cell1.configure(with: recordVO.thumbURL2000 ?? "")
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
            if currentSubmenuSelection == 0 && indexPath.item < 2 {
                cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item),isDetailsFieldEditable: true)
            } else {
                cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item))
            }
            return cell3
            } else {
                let cell4 = collectionView.dequeueReusableCell(withReuseIdentifier: SaveButtonCollectionViewCell.identifier, for: indexPath) as! SaveButtonCollectionViewCell
                cell4.configure(title: .save)
                return cell4
            }
        }
        
        
//        cell.rightButtonTapAction = { _ in
//            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
//        }
    }
    
    
    func cellTitle(itemNumber: Int) -> String {
        if currentSubmenuSelection == 0 {
            return infoSubmenuItems[itemNumber]
        }
        return detailsSubmenuItems[itemNumber]
    }
    func cellDetails(itemNumber: Int) -> String {
        var details: String!
        switch itemNumber {
        case 0:
            if currentSubmenuSelection == 0 {
                details = self.recordVO.displayName
            } else {
                details = convertDateFormater(self.recordVO.displayDT ?? "")
            }
        case 1:
            if currentSubmenuSelection == 0 {
                details = self.recordVO.recordVODescription ?? ""
            } else {
                details = String(self.recordVO.uploadAccountID!)
            }
        case 2:
            if currentSubmenuSelection == 0 {
                details = convertDateFormater(self.recordVO.displayDT ?? "")
            } else {
                details = convertDateFormater(self.recordVO.updatedDT ?? "")
            }
        case 3:
            if currentSubmenuSelection == 0 {
                if
                    let street = self.recordVO.locnVO?.streetName,
                    //let city = self.recordVO.locnVO?.locality,
                    let country = self.recordVO.locnVO?.country {
                    details = "\(street),\(country)"
                }
                else {
                    details = ""
                }
            } else {
                details = convertDateFormater(self.recordVO.createdDT ?? "")
            }
        case 4:
            if currentSubmenuSelection == 0 {
                details = ""
            } else {
                details = convertDateFormater(self.recordVO.derivedDT ?? "")
            }
        case 5:
            details = ByteCountFormatter.string(fromByteCount: Int64(self.recordVO.size ?? 0), countStyle: .file)
        case 6:
            details = URL(string: self.recordVO.type)?.pathExtension
        case 7:
            details = URL(string: self.recordVO.uploadFileName)?.deletingPathExtension().absoluteString
        case 8:
            details = URL(string: self.recordVO.uploadFileName)?.pathExtension
        default:
            details = ""
        }
        return details
    }
    func convertDateFormater(_ date: String) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let dateProcessed = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "yyyy-MM-dd h:mm:ss a"
            return  dateFormatter.string(from: dateProcessed)
        } else {
            return ""
        }
    }
}

extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath == [0,0] {
            let fileDetailsVC = UIViewController.create(withIdentifier: .filePreview , from: .main) as! FilePreviewViewController
            fileDetailsVC.file = file
            
            navigationController?.setViewControllers([fileDetailsVC], animated: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
        case (0,1):
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case (1,5):
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
        case (1,_):
            return CGSize(width: UIScreen.main.bounds.width, height: 65)
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 10)
        }
        
//        if indexPath[0] == 0 {
//            if indexPath.item == 0 {
//                return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
//            } else if indexPath.item == 1 {
//                return CGSize(width: UIScreen.main.bounds.width, height: 40)
//            }
//        } else if indexPath[0] == 1 {
//            return CGSize(width: UIScreen.main.bounds.width, height: 100)
//        }
//        return CGSize(width: UIScreen.main.bounds.width, height: 10)
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
