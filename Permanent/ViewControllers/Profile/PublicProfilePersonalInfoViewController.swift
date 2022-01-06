//
//  PublicProfilePersonalInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class PublicProfilePersonalInfoViewController: BaseViewController<PublicProfilePageViewModel> {
    
    @IBOutlet weak var fullNameTitleLabel: UILabel!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var nicknameTitleLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var genderTitleLabel: UILabel!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var birthDateTitleLabel: UILabel!
    @IBOutlet weak var birthDateTextField: UITextField!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var fullNameHintLabel: UILabel!
    @IBOutlet weak var nicknameHintLabel: UILabel!
    @IBOutlet weak var genderHintLabel: UILabel!
    @IBOutlet weak var birthDateHintLabel: UILabel!
    @IBOutlet weak var birthLocationHintLabel: UILabel!
    
    var screenTitle: String = "Personal Information".localized()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = screenTitle.localized()
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        setupNavigationBar()
        
        initUI()
        
        fullNameTextField.delegate = self
        nicknameTextField.delegate = self
        genderTextField.delegate = self
        birthDateTextField.delegate = self
        locationTextField.delegate = self
        
        addDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //      NotificationCenter.default.removeObserver(self)
        view.endEditing(true)
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    func initUI() {
        
        fullNameTitleLabel.textColor = .middleGray
        fullNameTitleLabel.font = Text.style12.font
        
        fullNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        fullNameTextField.layer.borderWidth = 0.5
        fullNameTextField.layer.cornerRadius = 3
        fullNameTextField.textColor = .middleGray
        fullNameTextField.font = Text.style7.font
        
        fullNameHintLabel.textColor = .lightGray
        fullNameHintLabel.font = Text.style8.font
        fullNameHintLabel.textAlignment = .left
        
        nicknameTitleLabel.textColor = .middleGray
        nicknameTitleLabel.font = Text.style12.font
        
        nicknameTextField.layer.borderColor = UIColor.lightGray.cgColor
        nicknameTextField.layer.borderWidth = 0.5
        nicknameTextField.layer.cornerRadius = 3
        nicknameTextField.textColor = .middleGray
        nicknameTextField.font = Text.style7.font
        
        nicknameHintLabel.textColor = .lightGray
        nicknameHintLabel.font = Text.style8.font
        nicknameHintLabel.textAlignment = .left
        
        genderTitleLabel.textColor = .middleGray
        genderTitleLabel.font = Text.style12.font
        
        genderTextField.layer.borderColor = UIColor.lightGray.cgColor
        genderTextField.layer.borderWidth = 0.5
        genderTextField.layer.cornerRadius = 3
        genderTextField.textColor = .middleGray
        genderTextField.font = Text.style7.font
        
        genderHintLabel.textColor = .lightGray
        genderHintLabel.font = Text.style8.font
        genderHintLabel.textAlignment = .left
        
        birthDateTitleLabel.textColor = .middleGray
        birthDateTitleLabel.font = Text.style12.font
        
        birthDateTextField.layer.borderColor = UIColor.lightGray.cgColor
        birthDateTextField.layer.borderWidth = 0.5
        birthDateTextField.layer.cornerRadius = 3
        birthDateTextField.textColor = .middleGray
        birthDateTextField.font = Text.style7.font
        
        birthDateHintLabel.textColor = .lightGray
        birthDateHintLabel.font = Text.style8.font
        birthDateHintLabel.textAlignment = .left
        
        locationTitleLabel.textColor = .middleGray
        locationTitleLabel.font = Text.style12.font
        
        locationTextField.layer.borderColor = UIColor.lightGray.cgColor
        locationTextField.layer.borderWidth = 0.5
        locationTextField.layer.cornerRadius = 3
        locationTextField.textColor = .middleGray
        locationTextField.font = Text.style7.font
        
        birthLocationHintLabel.textColor = .lightGray
        birthLocationHintLabel.font = Text.style8.font
        birthLocationHintLabel.textAlignment = .left
        
        fullNameTitleLabel.text = "Full Name".localized()
        nicknameTitleLabel.text = "Nickname".localized()
        genderTitleLabel.text = "Gender".localized()
        birthDateTitleLabel.text = "Birth Date".localized()
        locationTitleLabel.text = "Birth Location".localized()
        
        fullNameHintLabel.text = "Full name".localized()
        nicknameHintLabel.text = "Aliases or nicknames".localized()
        genderHintLabel.text = "Gender".localized()
        birthDateHintLabel.text = "YYYY-MM-DD"
        birthLocationHintLabel.text = "Choose a location".localized()
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension PublicProfilePersonalInfoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case fullNameTextField:
            fullNameHintLabel.isHidden = true
        case nicknameTextField:
            nicknameHintLabel.isHidden = true
        case genderTextField:
            genderHintLabel.isHidden = true
        case birthDateTextField:
            birthDateHintLabel.isHidden = true
        case locationTextField:
            birthLocationHintLabel.isHidden = true
        default:
            return
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let textFieldText = textField.text else { return }
        
        switch textField {
        case fullNameTextField:
            if textFieldText.isEmpty {
                fullNameHintLabel.isHidden = false
            }
        case nicknameTextField:
            if textFieldText.isEmpty {
                nicknameHintLabel.isHidden = false
            }
        case genderTextField:
            if textFieldText.isEmpty {
                genderHintLabel.isHidden = false
            }
        case birthDateTextField:
            if textFieldText.isEmpty {
                birthDateHintLabel.isHidden = false
            }
        case locationTextField:
            if textFieldText.isEmpty {
                birthLocationHintLabel.isHidden = false
            }
        default:
            return
        }
    }
}
