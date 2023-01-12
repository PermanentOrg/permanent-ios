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
        
        loginLabel.text = .forgotPassword
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
        guard let email = emailField.text, viewModel?.areFieldsValid(emailField: email) ?? false else {
            showAlert(title: .error, message: .invalidFields)
            return
        }
        
        viewModel?.forgotPassword(withEmail: email, then: { status in
            switch status {
            case .success:
                let alert = UIAlertController(title: "Change password link was sent".localized(), message: "An email has been sent to provided address".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok".localized(), style: .default, handler: {_ in
                    self.navigationController?.popViewController(animated: true)
                }))
                
                self.present(alert, animated: true)
            case .error(let message):
                let alert = UIAlertController(title: .error, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: .retry, style: .default, handler: nil))
                
                self.present(alert, animated: true)
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
