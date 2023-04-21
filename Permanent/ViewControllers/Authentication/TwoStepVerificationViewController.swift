//
//  TwoStepVerificationViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//

import UIKit

class TwoStepVerificationViewController: BaseViewController<AuthViewModel> {
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var extraInfoLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var skipButton: UIButton!
    @IBOutlet private var phoneField: CustomTextField!
    @IBOutlet private var copyrightLabel: UILabel!
    
    var signUpCredentials: SignUpCredentials?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        
        viewModel = AuthViewModel()
        
        titleLabel.text = .twoStepTitle
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        subtitleLabel.text = .twoStepSubtitle
        subtitleLabel.textColor = .white
        subtitleLabel.font = Text.style2.font
        
        extraInfoLabel.text = .addLater
        extraInfoLabel.textColor = .lightGray
        extraInfoLabel.font = Text.style6.font
        
        confirmButton.setTitle(.submit, for: [])
    
        skipButton.setTitle(.skip, for: [])
        skipButton.setFont(Text.style9.font)
        skipButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = .copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        phoneField.placeholder = "( ___ ) ___ - ____"
        phoneField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: RoundedButton) {
        guard
            let phone = phoneField.text,
            phone.isNotEmpty, phone.isPhoneNumber
        else {
            showAlert(title: .error, message: .invalidPhone)
            return
        }
    }
    
    @IBAction func skipAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func openMainScreen() {
        //AppDelegate.shared.rootViewController.setDrawerRoot()
    }
    
    private func sendVerificationCodeSMS(forAccount id: String, email: String) {
    }
}

extension TwoStepVerificationViewController: UITextFieldDelegate {
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
