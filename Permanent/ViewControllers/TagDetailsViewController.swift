//
//  TagDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.04.2021.
//

import UIKit

protocol TagDetailsViewControllerDelegate: AnyObject {
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
    let maximumNumberOfCharactersForTagName: Int = 16

    weak var delegate: TagDetailsViewControllerDelegate?
    
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    
    var sortedArray: [SortedTagVO] = []
    var filteredTagVO: [TagVO] = []
    
    @IBOutlet weak var tagSearchBar: UISearchBar!
    @IBOutlet weak var addTagButton: RoundedButton!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()

        tagsCollectionView.register(UINib(nibName: TagCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
        
        self.tagsCollectionView.dataSource = self
        self.tagsCollectionView.delegate = self
        self.tagSearchBar.delegate = self
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
        
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .black
            navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = .black
        } else {
            navigationController?.navigationBar.barTintColor = .black
        }
    }
    
    func initUI() {
        view.backgroundColor = .black
        
        navigationItem.title = "Edit Tags".localized()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        
        tagSearchBar.setDefaultStyle(placeholder: "Add new tag".localized())
        tagSearchBar.setFont(Text.style2.font)
        tagSearchBar.setPlaceholderTextColor(.lightGray)
        tagSearchBar.setTextColor(.lightGray)
        tagSearchBar.setBackgroundColor(.darkGray)
        tagSearchBar.tintColor = .lightGray
        tagSearchBar.barTintColor = .lightGray
        tagSearchBar.autocapitalizationType = .none
        
        addTagButton.configureActionButtonUI(title: "Add".localized(), bgColor: .barneyPurple, buttonHeight: CGFloat(30))
        
        tagsCollectionView.backgroundColor = .clear
        tagsCollectionView.indicatorStyle = .white
        
        initTagsState()
    
        let columnLayout = TagsCollectionViewLayout()
        tagsCollectionView.collectionViewLayout = columnLayout
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        let dispatchGroup = DispatchGroup()
        showSpinner(colored: .lightGray)
        
        let addedTags: [String] = sortedArray.filter({ $0.forAdding }).map({ $0.tagVO.tagVO.name ?? "" })
        
        dispatchGroup.enter()
        viewModel?.addTag(tagNames: addedTags, completion: { (result) in
            dispatchGroup.leave()
        })
        
        let removedTags: [TagVO] = sortedArray.filter({ $0.forRemoval }).map({ $0.tagVO })
        
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
    
    @IBAction func addTagButtonAction(_ sender: Any) {
        
        if let findTag = tagSearchBar.text,
           !findTag.isEmpty,
           sortedArray.first(where: { $0.tagVO.tagVO.name == findTag }) == nil {
            sortedArray.insert(SortedTagVO(tagVO: TagVO(tagVO: TagVOData(name: findTag, status: String(), tagId: Int(), type: String(), createdDT: String(), updatedDT: String())), checked: true, forAdding: true, forRemoval: false), at: 0)
            
            tagSearchBar.text = ""
            
            filteredTagVO = sortedArray.map({ (item) -> TagVO in
                return item.tagVO
            })
            self.tagsCollectionView.reloadData()
            self.view.endEditing(true)
        }
    }
    
    func initTagsState() {
        showSpinner(colored: .lightGray)
        viewModel?.getTagsByArchive(archiveId: viewModel?.file.archiveId ?? 0, completion: { result in
            guard let tagsArchive = result else {
                self.hideSpinner()
                return
            }
            
            self.sortedArray = tagsArchive.map( { SortedTagVO(tagVO: $0) } )
            
            if let tags = self.recordVO?.tagVOS {
                for tagItem in tags {
                    var idx : Int?
                    idx = self.sortedArray.firstIndex(where: { $0.tagVO.tagVO.name == tagItem.name})

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
        
        if let tagName = filteredTagVO[indexPath.row].tagVO.name,
           let isChecked = sortedArray.first(where: { $0.tagVO.tagVO.name == tagName })?.checked {
            cell.configure(name: tagName, isChecked: isChecked)
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
        if let cellIndex = sortedArray.firstIndex(where: { $0.tagVO.tagVO.name == filteredTagVO[indexPath.row].tagVO.name}) {
            sortedArray[cellIndex].checked = !sortedArray[cellIndex].checked
            sortedArray[cellIndex].forAdding = sortedArray[cellIndex].checked
            sortedArray[cellIndex].forRemoval = !sortedArray[cellIndex].checked
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if  let name = filteredTagVO[indexPath.row].tagVO.name,
            let isChecked = sortedArray.first(where: { $0.tagVO.tagVO.name == name })?.checked {
            let additionalSpace: CGFloat = isChecked ? ( 45 ) : ( 35 )
            let attributedName = NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: Text.style2.font as Any])
            let width = attributedName.boundingRect(with: CGSize(width: collectionView.bounds.width, height: 30), options: [], context: nil).size.width
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        addTagButtonAction(searchBar)
    }
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location >= maximumNumberOfCharactersForTagName { return false }
        return true
    }
}
