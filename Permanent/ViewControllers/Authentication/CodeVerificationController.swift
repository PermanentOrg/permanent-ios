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
        
        titleLabel.text = Translations.enterVerificationCode
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        codeField.placeholder = Translations.enterCode
        codeField.delegate = self
        codeField.smartInsertDeleteType = .no
        codeField.textContentType = .oneTimeCode
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
            navigationController?.navigate(to: .main, from: .main)
        case .error(let message):
            showAlert(title: Translations.error, message: message)
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        return newLength <= 4 // TODO: Make a property in TextField for this value
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        scrollView.setContentOffset(.zero, animated: true)
        return false
    }
}
