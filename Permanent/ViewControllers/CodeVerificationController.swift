//
//  VerificationCodeController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//

import UIKit

class CodeVerificationController: BaseViewController<VerificationCodeViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var codeField: CustomTextField!
    
    var verificationType: CodeVerificationType = .mfa
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = VerificationCodeViewModel()
        
        titleLabel.text = .enterVerificationCode
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        codeField.placeholder = .enterCode
        codeField.delegate = self
        codeField.smartInsertDeleteType = .no
        codeField.textContentType = .oneTimeCode
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(confirmAction(_:)) )
        toolBar.setItems([flexibleSpace,doneButton], animated: false)
        
        codeField.inputAccessoryView = toolBar
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: UIButton) {
        guard
            let email: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.emailStorageKey),
            let code = codeField.text,
            code.isNotEmpty else { return }
        
        let credentials = VerifyCodeCredentials(email, code, verificationType)
        
        showSpinner(colored: .white)
        viewModel?.verify(for: credentials, then: { status in
            DispatchQueue.main.async {
                self.handleVerifyStatus(status)
            }
        })
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

extension CodeVerificationController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
        
        let point = CGPoint(x: 0, y: textField.frame.origin.y - 10)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        scrollView.setContentOffset(.zero, animated: true)
        return false
    }
}
