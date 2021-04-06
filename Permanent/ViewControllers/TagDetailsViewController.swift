//
//  TagDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.04.2021.
//

import UIKit

class TagDetailsViewController: BaseViewController<FilePreviewViewModel> {
    
    @IBOutlet weak var tagFindSearchBar: UISearchBar!
    @IBOutlet weak var AddTagButton: RoundedButton!
    @IBOutlet weak var tagsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleNavBar()
        initUI()
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
        
        AddTagButton.configureActionButtonUI(title: "Add".localized(), bgColor: .barneyPurple)
        
        tagsTableView.backgroundColor = .clear
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        showSpinner()
        
    }
}
