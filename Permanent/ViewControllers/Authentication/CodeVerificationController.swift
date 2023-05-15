//
//  VerificationCodeController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//

import UIKit

class CodeVerificationController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var codeField: AuthTextField!
    @IBOutlet weak var verificationCodeTitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        verificationCodeTitleLabel.text = .enterVerificationCode
        verificationCodeTitleLabel.textColor = .tangerine
        verificationCodeTitleLabel.font = TextFontStyle.style.font
        
        confirmButton.setTitle("Verify".localized(), for: .normal)
        confirmButton.setFont(TextFontStyle.style16.font)
        confirmButton.setTitleColor(.primary, for: [])
        confirmButton.layer.cornerRadius = 0
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = TextFontStyle.style12.font
        
        codeField.placeholder = "Code".uppercased()
        codeField.accessibilityLabel = "Code"
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(confirmAction(_:)) )
        toolBar.setItems([flexibleSpace,doneButton], animated: false)

        codeField.inputAccessoryView = toolBar
        
        addDismissKeyboardGesture()
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: UIButton) {
        closeKeyboard()
        guard let code = codeField.text, code.isNotEmpty else {
            showErrorAlert(message: "Enter the received code.".localized())
            return
        }
        
        AuthenticationManager.shared.verify2FA(code: code) { result in
            switch result {
            case .success:
                self.dismiss(animated: true)
                
                if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    AppDelegate.shared.rootViewController.setRoot(named: .accountOnboarding, from: .accountOnboarding)
                }
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        }
    }
    
    fileprivate func handleVerifyStatus(_ status: RequestStatus) {
        hideSpinner()
        
        switch status {
        case .success:
            AppDelegate.shared.rootViewController.setDrawerRoot()
        case .error(let message):
            showAlert(title: .error, message: message)
        }
    }
}
