//
//  RecoverPasswordViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2022.
//

import UIKit

class RecoverPasswordViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet weak var recoverPasswordButton: RoundedButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var separatorTextLabel: UILabel!
    @IBOutlet weak var emailField: AuthTextField!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    
    private let overlayView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        screenTitle.text = "Forgot Password?".localized()
        screenTitle.textColor = .tangerine
        screenTitle.font = Text.style.font
        
        emailField.placeholder = .email.uppercased()
        emailField.accessibilityLabel = "Email"
        
        backButton.setTitle("Back to Sign in".localized(), for: [])
        backButton.setFont(Text.style20.font)
        backButton.setTitleColor(.white, for: [])
        
        recoverPasswordButton.setTitle("Recover password".localized(), for: .normal)
        recoverPasswordButton.setFont(Text.style16.font)
        recoverPasswordButton.setTitleColor(.primary, for: [])
        recoverPasswordButton.layer.cornerRadius = 0
        recoverPasswordButton.isUserInteractionEnabled = false
        recoverPasswordButton.alpha = 0.6
        
        separatorTextLabel.text = "OR".localized().uppercased()
        separatorTextLabel.textColor = .white.withAlphaComponent(0.5)
        separatorTextLabel.backgroundColor = .darkBlue
        separatorTextLabel.font = Text.style30.font
        separatorTextLabel.setTextSpacingBy(value: 0.8)
        
        separatorView.backgroundColor = .white.withAlphaComponent(0.5)
        separatorViewHeight.constant = 1.0 / UIScreen.main.scale
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white.withAlphaComponent(0.5)
        copyrightLabel.font = Text.style12.font
        
        emailField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func recoverPasswordAction(_ sender: Any) {
        closeKeyboard()
        
        guard let email = emailField.text, viewModel?.areFieldsValid(emailField: email) ?? false else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        
        showSpinner()
        viewModel?.forgotPassword(withEmail: email, then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                let alert = UIAlertController(title: "Success!".localized(), message: "You will receive an email with instructions to reset your password.".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok".localized(), style: .default, handler: {_ in
                    self.navigationController?.popViewController(animated: true)
                }))
                
                self.present(alert, animated: true)
            case .error(let message):
                self.showAlert(title: "Oops!", message: message)
                
            }
        })
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension RecoverPasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        recoverPasswordAction(self)
        return false
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text, let isValidEmail = viewModel?.areFieldsValid(emailField: text), isValidEmail {
            recoverPasswordButton.isUserInteractionEnabled = true
            recoverPasswordButton.alpha = 1
        } else {
            recoverPasswordButton.isUserInteractionEnabled = false
            recoverPasswordButton.alpha = 0.6
        }
    }
}
