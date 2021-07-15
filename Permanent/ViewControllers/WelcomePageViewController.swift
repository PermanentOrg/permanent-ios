//
//  WelcomePageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.07.2021.
//

import UIKit

class WelcomePageViewController: BaseViewController<AuthViewModel>  {
    
    var archiveName: String?
    
    @IBOutlet weak var welcomePageView: UIView!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var primaryLabelField: UILabel!
    @IBOutlet weak var secondaryLabelField: UILabel!
    @IBOutlet weak var acceptButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        PreferencesManager.shared.set(true, forKey: Constants.Keys.StorageKeys.viewedWelcomePageStorageKey)
        dismiss(animated: true, completion: nil)
    }
    
    func initUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        welcomePageView.backgroundColor = .darkBlue
        welcomePageView.clipsToBounds = true
        welcomePageView.layer.cornerRadius = 10
        
        primaryLabelField.textColor = .white
        primaryLabelField.font = Text.style2.font
        primaryLabelField.numberOfLines = 2
        primaryLabelField.text = "Welcome to The \(archiveName ?? "Lucian Cerbu personal") Archive".localized()
        
        secondaryLabelField.textColor = .white
        secondaryLabelField.font = Text.style2.font
        secondaryLabelField.numberOfLines = 4
        secondaryLabelField.text = "This archive represents your personal \n digital legacy. Upload your most \nimportant digital records then share \nthem with total control.".localized()
        
        acceptButton.configureActionButtonUI(title: "Start Preserving".localized(), bgColor: .secondary, buttonHeight: 45)

    }
}
