//
//  RecoverPasswordViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2022.
//

import UIKit

class RecoverPasswordViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet weak var recoverPasswordButton: RoundedButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet private var emailField: CustomTextField!
    
    private let overlayView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        viewModel = AuthViewModel()
        
        loginLabel.text = .login
        loginLabel.textColor = .white
        loginLabel.font = Text.style.font
        
        emailField.placeholder = .email
        
        backButton.setTitle("Go back to log in?".localized(), for: [])
        backButton.setFont(Text.style5.font)
        backButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        emailField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func recoverPasswordAction(_ sender: Any) {
        closeKeyboard()
        guard viewModel?.areFieldsValid(nameField: "noName", emailField: emailField.text, passwordField: "12345678") ?? false else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        showAlert(title: "Password was sent", message: "Password was sent to your email")
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension RecoverPasswordViewController: UITextFieldDelegate {
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
        recoverPasswordAction(self)
        return false
    }
}
