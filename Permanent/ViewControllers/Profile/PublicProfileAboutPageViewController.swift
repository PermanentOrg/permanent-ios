//
//  PublicProfileAboutPageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.11.2021.
//

import UIKit

class PublicProfileAboutPageViewController: BaseViewController<PublicProfilePageViewModel> {
    
    var shortDescription: String?
    var longDescription:String?
    var screenTitle: String = "About This Archive".localized()
    var archiveType: ArchiveType!
    
    @IBOutlet weak var shortAboutDescriptionTitleLabel: UILabel!
    @IBOutlet weak var shortAboutDescriptionTextView: UITextView!
    @IBOutlet weak var longAboutDescriptionTextView: UITextView!
    @IBOutlet weak var longAboutDescriptionTitleLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = screenTitle.localized()
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        setupNavigationBar()
        
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonAction(_:)))
    }
    
    func initUI() {
        
        shortAboutDescriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        shortAboutDescriptionTextView.layer.borderWidth = 0.5
        shortAboutDescriptionTextView.layer.cornerRadius = 5
        
        longAboutDescriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        longAboutDescriptionTextView.layer.borderWidth = 0.5
        longAboutDescriptionTextView.layer.cornerRadius = 5
        
        shortAboutDescriptionTitleLabel.text = "What is this Archive for?".localized()
        if let shortDescription = shortDescription {
            shortAboutDescriptionTextView.text = shortDescription
        } else {
            shortAboutDescriptionTextView.text = "Add a short description about the purpose of this Archive.".localized()
        }
        
        if let longDescription = longDescription {
            longAboutDescriptionTextView.text = longDescription
        } else {
            switch archiveType {
            case .person:
                longAboutDescriptionTextView.text = "Tell the story of the Person this Archive is for.".localized()
            case .family:
                longAboutDescriptionTextView.text = "Tell the story of the Family this Archive is for.".localized()
            case .organization:
                longAboutDescriptionTextView.text = "Tell the story of the Organization this Archive is for.".localized()
            case .none: break
            }
        }
        
        switch archiveType {
        case .person:
            longAboutDescriptionTitleLabel.text = "Tell us about this Person".localized()
        case .family:
            longAboutDescriptionTitleLabel.text = "Tell us about this Family".localized()
        case .organization:
            longAboutDescriptionTitleLabel.text = "Tell us about this Organization".localized()
        case .none: break
        }
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
}
