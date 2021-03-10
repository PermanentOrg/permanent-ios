//
//  FileDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.03.2021.
//

import UIKit

let reuseIdentifier = "CellIdentifer";

class FileDetailsViewController: BaseViewController<FileDetailsViewModel> {
    
    var file: FileViewModel!
    let infoSubmenuItems: [String] = ["Name", "Description", "Date", "Location", "Tags"]
    let detailsSubmenuItems: [String] = ["Uploaded", "Uploaded By","Created","File Created","Size","File Type","Original File name:","Original File Type"]
    var infoDetailsCellNumber: [Int]!
    var currentSubmenuSelection = 0
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5)
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .black
        
        collectionView.register(FileDetailsTopCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsTopCollectionViewCell.identifier)
        collectionView.register(FileDetailsMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier)
        collectionView.register(FileDetailsBottomCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSpinner(isLoading: true)
    }
    
    func initUI() {
        view.backgroundColor = .black
        styleFileDetailsNavBar()
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
        
        infoDetailsCellNumber = [infoSubmenuItems.count,detailsSubmenuItems.count]
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
extension FileDetailsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        print("you tapped me.")
        
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
                cell1.configure(with: file.thumbnailURL2000!)
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
            let cell3 = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell
            cell3.configure(title: cellTitle(itemNumber: indexPath.item), details: cellDetails(itemNumber: indexPath.item))
            return cell3
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
                details = self.file.name
            } else {
                details = ""
            }
        case 1:
            if currentSubmenuSelection == 0 {
                details = self.file.description
            } else {
                details = ""
            }
        case 2:
            if currentSubmenuSelection == 0 {
                details = self.file.date
            } else {
                details = ""
            }
        case 3:
            if currentSubmenuSelection == 0 {
                details = ""
            } else {
                details = ""
            }
        case 4:
            if currentSubmenuSelection == 0 {
                details = ""
            } else {
                details = ByteCountFormatter.string(fromByteCount: self.file.size, countStyle: .file)
            }
        case 6:
            details = self.file.uploadFileName
        default:
            details = ""
        }
        return details
    }
}

extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath[0] == 0 {
            if indexPath.item == 0 {
                return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5)
            } else if indexPath.item == 1 {
                return CGSize(width: UIScreen.main.bounds.width, height: 40)
            }
        } else if indexPath[0] == 1 {
            return CGSize(width: UIScreen.main.bounds.width, height: 100)
        }
        return CGSize(width: UIScreen.main.bounds.width, height: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0)
    }
}
