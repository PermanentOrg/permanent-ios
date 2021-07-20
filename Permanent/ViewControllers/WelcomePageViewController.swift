//
//  WelcomePageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.07.2021.
//

import UIKit

class WelcomePageViewController: UIViewController  {
    
    var archiveName: String?
    
    @IBOutlet weak var welcomePageView: UIView!
    @IBOutlet weak var pageImage: UIImageView!
    @IBOutlet weak var primaryLabelField: UILabel!
    @IBOutlet weak var secondaryLabelField: UILabel!
    @IBOutlet weak var acceptButton: RoundedButton!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        closePopUp()
    }
    
    @IBAction func closeButton(_ sender: Any) {
        closePopUp()
    }
    
    func initUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        welcomePageView.backgroundColor = .darkBlue
        welcomePageView.clipsToBounds = true
        welcomePageView.layer.cornerRadius = 10
        
        primaryLabelField.textColor = .white
        primaryLabelField.font = Text.style2.font
        primaryLabelField.numberOfLines = 2
        primaryLabelField.text = "Welcome to The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName!)
        
        secondaryLabelField.textColor = .white
        secondaryLabelField.font = Text.style2.font
        secondaryLabelField.numberOfLines = 0
        secondaryLabelField.text = "This archive represents your personal digital legacy. Upload your most important digital records then share them with total control.".localized()
        
        acceptButton.configureActionButtonUI(title: "Start Preserving".localized(), bgColor: .secondary, buttonHeight: 45)

    }
    
    func closePopUp() {
        UserDefaults.standard.setValue(nil, forKey: Constants.Keys.StorageKeys.signUpNameStorageKey)
        dismiss(animated: true, completion: nil)
    }
}
