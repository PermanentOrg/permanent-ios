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

struct SortedTagVO {
    var tagVO: TagVO
    var checked: Bool = false
    var forAdding: Bool = false
    var forRemoval: Bool = false
}

class TagDetailsViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var tagVOS: [TagVOData]?
    var archiveTagVOS: [TagVO] = []
    var addTagVOS: TagVO = TagVO(tagVO: TagVOData(name: "", status: "", tagId: 0, type: "", createdDT: "", updatedDT: ""))
    var sortedArray: [SortedTagVO] = []
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
        showSpinner(colored: .lightGray)
        
        let forAddingBool = sortedArray.map({ (SortedTagVO) in
            return SortedTagVO.forAdding
         })
        let forAddingNames = sortedArray.map { (item) -> String in
            return item.tagVO.tagVO.name ?? ""
        }
        
        let addedNames: [String] = zip(forAddingBool, forAddingNames).filter{ $0.0 }.map{ $1 }
        
        dispatchGroup.enter()
        viewModel?.addTag(tagNames: addedNames, completion: { (result) in
            dispatchGroup.leave()
        })
        
        let forRemovalBool = sortedArray.map { (item) -> Bool in
            return item.forRemoval
        }
        let forRemovalTags = sortedArray.map { (item) -> TagVO in
            return item.tagVO
        }
        let removedTags: [TagVO] = zip(forRemovalBool, forRemovalTags).filter{ $0.0 }.map{ $1 }
        
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
            
            sortedArray.insert(SortedTagVO(tagVO: addTagVOS, checked: true, forAdding: true, forRemoval: false), at: 0)
            
            self.tagFindSearchBar.text = ""
            
            filteredTagVO = sortedArray.map({ (item) -> TagVO in
                return item.tagVO
            })
            
            self.tagsCollectionView.reloadData()
            self.view.endEditing(true)
        }
    }
    
    func initTagsState()
    {
        showSpinner(colored: .lightGray)
        viewModel?.getTagsByArchive(archiveId: viewModel?.file.archiveId ?? 0, completion: { result in
            guard let tagsArchive = result else {
                return
            }
            self.archiveTagVOS = tagsArchive
            
            for (index,_) in self.archiveTagVOS.enumerated() {
                self.sortedArray.append(SortedTagVO(tagVO: self.archiveTagVOS[index]))
            }
            
            if let tags = self.tagVOS {
                for tagItem in tags {
                    var idx : Int?
                    idx = self.archiveTagVOS.firstIndex(where: { $0.tagVO.name == tagItem.name })
                    if idx != nil { self.sortedArray[idx!].checked = true }
                }
            }
            
            self.sortedArray.sort { (_, arg0) -> Bool in !arg0.checked }
            self.filteredTagVO = self.sortedArray.map({ (item) -> TagVO in
                return item.tagVO
            })

            self.tagsCollectionView.reloadData()
            self.hideSpinner()
        })
    }
}

extension TagDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTagVO.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier, for: indexPath) as! TagCollectionViewCell
        
        if let tagName = filteredTagVO[indexPath.row].tagVO.name {
            cell.configure(name: tagName, isVisible: sortedArray[indexPath.row].checked)
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
        
        sortedArray[indexPath.row].checked = !sortedArray[indexPath.row].checked
        sortedArray[indexPath.row].forAdding = sortedArray[indexPath.row].checked
        sortedArray[indexPath.row].forRemoval = !sortedArray[indexPath.row].checked
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let additionalSpace: CGFloat = (sortedArray[indexPath.row].checked == true) ? ( 45 ) : ( 35 )
        
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
        
        let currentTagVO = sortedArray.map({ (item) -> TagVO in
            return item.tagVO
        })
        
        filteredTagVO = searchText.isEmpty ? currentTagVO  : currentTagVO.filter({ (tag) -> Bool in
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
