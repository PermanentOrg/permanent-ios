//
//  TagDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.04.2021.
//

import UIKit

protocol TagDetailsViewControllerDelegate: class {
    func tagDetailsViewControllerDidUpdate(_ tagVC: TagDetailsViewController)
}

class TagDetailsViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var tagVOS: [TagVOData]?
    var archiveTagVOS: [TagVO] = []
    var addTagVOS: TagVO = TagVO(tagVO: TagVOData(name: "", status: "", tagId: 0, type: "", createdDT: "", updatedDT: ""))
    var checked,forRemoval,forAdd: [Bool]!
    var filteredTagVO: [TagVO] = []
    var isSearching: Bool = false
    private let spacing: CGFloat = 16.0
    
    weak var delegate: TagDetailsViewControllerDelegate?
    
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    
    @IBOutlet weak var tagFindSearchBar: UISearchBar!
    @IBOutlet weak var AddTagButton: RoundedButton!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()

        tagsCollectionView.register(UINib(nibName: TagCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
        
        self.tagsCollectionView.dataSource = self
        self.tagsCollectionView.delegate = self
        self.tagFindSearchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    func initUI() {
        view.backgroundColor = .black
        
        navigationItem.title = "Edit Tags".localized()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        
        tagFindSearchBar.setDefaultStyle(placeholder: "Add new tag".localized())
        tagFindSearchBar.setFont(Text.style2.font)
        tagFindSearchBar.setPlaceholderTextColor(.lightGray)
        tagFindSearchBar.setTextColor(.lightGray)
        tagFindSearchBar.setBackgroundColor(.darkGray)
        tagFindSearchBar.tintColor = .lightGray
        tagFindSearchBar.barTintColor = .lightGray
        
        AddTagButton.configureActionButtonUI(title: "Add".localized(), bgColor: .barneyPurple, buttonHeight: CGFloat(30))
        
        tagsCollectionView.backgroundColor = .clear
        tagsCollectionView.indicatorStyle = .white
        
        initTagsState()
    
        let columnLayout = CustomViewFlowLayout()
        tagsCollectionView.collectionViewLayout = columnLayout
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        let dispatchGroup = DispatchGroup()
        showSpinner()
        var tempName: [String] = []
        archiveTagVOS.forEach { (result) in
            if let name = result.tagVO.name {
                tempName.append(name) }
        }

        let addedNames: [String] = zip(forAdd, tempName).filter { $0.0 }.map { $1 }
        dispatchGroup.enter()
        viewModel?.addTag(tagNames: addedNames, completion: { (result) in
            dispatchGroup.leave()
        })
        
        var removedTags: [TagVO] = []
        for itemNumber in 0...forRemoval.count - 1 {
            if forRemoval[itemNumber] {
                removedTags.append(archiveTagVOS[itemNumber])
            }
        }
        dispatchGroup.enter()
        viewModel?.deleteTag(tagVO: removedTags, completion: { (result) in
            dispatchGroup.leave()
            })   
       
        dispatchGroup.notify(queue: .main) {
            self.hideSpinner()
            self.delegate?.tagDetailsViewControllerDidUpdate(self)
            self.dismiss(animated: true, completion: nil)
        }

    }
    
    @IBAction func AddTagButtonAction(_ sender: Any) {
        var tagsList: [String] = []
        for item in archiveTagVOS {
            if let itemName = item.tagVO.name {
                tagsList.append(itemName.lowercased())
            }
        }
        if let findTag = tagFindSearchBar.text,
           !findTag.isEmpty,
           !tagsList.contains(findTag.lowercased())
        {
            let processedElements = archiveTagVOS.compactMap { (result) -> TagVOData in
                return result.tagVO
            }
            if let currentTag = processedElements.first {
                addTagVOS.tagVO = currentTag
            }
            addTagVOS.tagVO.name = findTag.lowercased()
            archiveTagVOS.insert(addTagVOS , at: 0)
            checked.insert(true, at: 0)
            forRemoval.insert(false, at: 0)
            forAdd.insert(true, at: 0)
            
            self.tagFindSearchBar.text = ""
            filteredTagVO = archiveTagVOS
            
            self.tagsCollectionView.reloadData()
            print()
        }
    }
    
    func initTagsState()
    {
        viewModel?.getTagsByArchive(archiveId: viewModel?.file.archiveId ?? 0, completion: { result in
            guard let tagsArchive = result else {
                return
            }
            self.archiveTagVOS = tagsArchive
            self.filteredTagVO = tagsArchive
            self.checked = [Bool].init(repeating: false, count: tagsArchive.count)
            self.forRemoval = [Bool].init(repeating: false, count: tagsArchive.count)
            self.forAdd = [Bool].init(repeating: false, count: tagsArchive.count)
            self.getCheckedTags()
            self.tagsCollectionView.reloadData()
        })
    }
    
    func getCheckedTags() {
        if let tags = tagVOS {
            for tagItem in tags {
                var idx : Int?
                idx = archiveTagVOS.firstIndex(where: { $0.tagVO.name == tagItem.name })
                if idx != nil { checked[idx!] = true }
            }
        }
    }
}

extension TagDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTagVO.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier, for: indexPath) as! TagCollectionViewCell
        
        if let tagName = filteredTagVO[indexPath.row].tagVO.name {
            cell.configure(name: tagName, isVisible: checked[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! TagCollectionViewCell
        
        UIView.animate(withDuration: 0.05, animations: { cell.alpha = 0.5 }) { (completed) in
            UIView.animate(withDuration: 0.05, animations: { cell.alpha = 1 })  { (completed) in
                collectionView.reloadData()
            }
        }
        
        checked[indexPath.row] = !checked[indexPath.row]

        forAdd[indexPath.row] = checked[indexPath.row]
        forRemoval[indexPath.row] = !checked[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let additionalSpace: CGFloat = (checked[indexPath.row] == true) ? ( 45 ) : ( 35 )
        
        if  let name = filteredTagVO[indexPath.row].tagVO.name {
            let attributedName = NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: Text.style2.font as Any])
            let width = attributedName.boundingRect(with: CGSize(width: 300, height: 30), options: [], context: nil).size.width
            return CGSize(width: additionalSpace + width , height: 40)
            }
        
        return CGSize(width: 0, height: 0)
    }
}

extension TagDetailsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTagVO = searchText.isEmpty ? archiveTagVOS : archiveTagVOS.filter({ (tag) -> Bool in
            return tag.tagVO.name?.lowercased().contains(searchText.lowercased()) ?? false
        })
        
        tagsCollectionView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
    }
}
