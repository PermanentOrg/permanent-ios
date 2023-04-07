//
//  ResetPasswordViewController.swift
//  Permanent
//
//

import UIKit

class ResetPasswordViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var resetPasswordButton: RoundedButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var screenTitle: UILabel!
    @IBOutlet weak var separatorTextLabel: UILabel!
    @IBOutlet weak var passwordsStackView: UIStackView!
    @IBOutlet weak var newPasswordField: AuthTextField!
    @IBOutlet weak var confirmPasswordField: AuthTextField!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewHeight: NSLayoutConstraint!
    
    var changePasswordId: String?
    
    private let overlayView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        screenTitle.text = "Reset Password".localized()
        screenTitle.textColor = .tangerine
        screenTitle.font = Text.style.font
        
        passwordsStackView.backgroundColor = .primary
        
        usernameField.text = ""
        
        newPasswordField.placeholder = "New Password".localized().uppercased()
        newPasswordField.accessibilityLabel = "New Password"
        
        confirmPasswordField.placeholder = "New Password".localized().uppercased()
        confirmPasswordField.accessibilityLabel = "New Password"
        
        backButton.setTitle("Back to Sign in".localized(), for: [])
        backButton.setFont(Text.style20.font)
        backButton.setTitleColor(.white, for: [])
        
        resetPasswordButton.setTitle("Reset password".localized(), for: .normal)
        resetPasswordButton.setFont(Text.style16.font)
        resetPasswordButton.setTitleColor(.primary, for: [])
        resetPasswordButton.layer.cornerRadius = 0
        resetPasswordButton.isUserInteractionEnabled = false
        resetPasswordButton.alpha = 0.6
        
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
        
        newPasswordField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func recoverPasswordAction(_ sender: Any) {
        closeKeyboard()
        
        guard let password = newPasswordField.text, password == confirmPasswordField.text,
            let changePwdId = changePasswordId else { return }
        
        showSpinner()
        viewModel?.resetPassword(changePasswordId: changePwdId, password: password, completion: { result in
            self.hideSpinner()
        })
        
//        guard let email = newPasswordField.text, viewModel?.areFieldsValid(emailField: email) ?? false else {
//            showAlert(title: "Oops!".localized(), message: "The email you entered is not a valid email.".localized())
//            return
//        }
//
//        showSpinner()
//        viewModel?.forgotPassword(withEmail: email, then: { status in
//            self.hideSpinner()
//            switch status {
//            case .success:
//                let alert = UIAlertController(title: "Success!".localized(), message: "If the email you entered is correct, you will receive instructions to reset your password.".localized(), preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Ok".localized(), style: .default, handler: {_ in
//                    self.navigationController?.popViewController(animated: true)
//                }))
//
//                self.present(alert, animated: true)
//            case .error(let message):
//                self.showAlert(title: "Oops!".localized(), message: message)
//
//            }
//        })
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        view.endEditing(true)
//        recoverPasswordAction(self)
        return false
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text  {
            resetPasswordButton.isUserInteractionEnabled = true
            resetPasswordButton.alpha = 1
        }
    }
}
