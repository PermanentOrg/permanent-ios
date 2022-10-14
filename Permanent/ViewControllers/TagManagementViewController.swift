//
//  TagManagementViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.10.2022.
//

import UIKit

class TagManagementViewController: BaseViewController<ManageTagsViewModel> {
    
    @IBOutlet weak var archiveTitleNameLabel: UILabel!
    @IBOutlet weak var archiveTitleTagsNbrLabel: UILabel!
    @IBOutlet weak var searchTags: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        initCollectionView()
    }
    
    func initUI() {
        title = "Manage Tags".localized()
        
        searchTags.updateHeight(height: 40, radius: 2)
        
        addButton.backgroundColor = .tangerine
        addButton.layer.cornerRadius = addButton.frame.height / 2
        addButton.shadowToBorder(showShadow: true)
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addButton.layer.shadowRadius = 3
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowColor = UIColor.gray.cgColor
    }
    
    func initCollectionView() {
        
    }
}
