//
//  TagDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.04.2021.
//

import UIKit

class TagDetailsViewController: BaseViewController<FilePreviewViewModel> {
    
    var file: FileViewModel!
    var tagVOS: [TagVOData]?
    var archiveTagVOS: [TagVO] = []
    var checked: [Bool]!
    var filteredTagVO: [TagVO] = []
    var isSearching: Bool = false
    
    @IBOutlet weak var tagFindSearchBar: UISearchBar!
    @IBOutlet weak var AddTagButton: RoundedButton!
    @IBOutlet weak var tagsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()
    
        tagsTableView.register(UINib(nibName: TagTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: TagTableViewCell.identifier)
        
        getTags()
        
        self.tagsTableView.dataSource = self
        self.tagsTableView.delegate = self
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
        tagFindSearchBar.setBackgroundColor(.galleryGray)
        tagFindSearchBar.setFont(Text.style2.font)
        tagFindSearchBar.setPlaceholderTextColor(.lightGray)
        
        AddTagButton.configureActionButtonUI(title: "Add".localized(), bgColor: .barneyPurple, buttonHeight: CGFloat(30))
        
        tagsTableView.backgroundColor = .clear
        tagsTableView.separatorColor = .lightGray
        tagsTableView.indicatorStyle = .white
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        showSpinner()
        
    }
    
    func getTags()
    {
        viewModel?.getTagsByArchive(archiveId: viewModel?.file.archiveId ?? 0, completion: { result in
            guard let tagsArchive = result else {
                return
            }
            self.archiveTagVOS = tagsArchive
            self.filteredTagVO = tagsArchive
            self.checked = [Bool].init(repeating: false, count: tagsArchive.count)
            self.getCheckedTags()
            self.tagsTableView.reloadData()
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

extension TagDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTagVO.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TagTableViewCell.identifier) as! TagTableViewCell
        
        if let tagName = filteredTagVO[indexPath.row].tagVO.name {
            cell.configure(name: tagName)
        }
        
        if checked[indexPath.row] {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        checked[indexPath.row] = !checked[indexPath.row]
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension TagDetailsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTagVO = searchText.isEmpty ? archiveTagVOS : archiveTagVOS.filter({ (tag) -> Bool in
            return tag.tagVO.name?.lowercased().contains(searchText.lowercased()) ?? false
        })
        
        tagsTableView.reloadData()
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