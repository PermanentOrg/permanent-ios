//
//  AccountSettingsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class AccountSettingsViewController:UIViewController {
    
    @IBOutlet weak var contentUpdateButton: RoundedButton!
    @IBOutlet weak var currentPasswordView: PasswordElementView!
    @IBOutlet weak var reTypePasswordView: PasswordElementView!
    @IBOutlet weak var newPasswordView: PasswordElementView!
    @IBOutlet weak var firstLineView: UIView!
    @IBOutlet weak var logWithFaceIdView: SwitchSettingsView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .security
        view.backgroundColor = .white
        firstLineView.backgroundColor = .lightGray
        logWithFaceIdView.text = .logInWithFingerPrint
        
        contentUpdateButton.configureActionButtonUI(title: .updatePassword)
        
        currentPasswordView.configurePasswordElementUI(label: .currentPassword, returnKey: UIReturnKeyType.next)
        reTypePasswordView.configurePasswordElementUI(label: .reTypePassword, returnKey: UIReturnKeyType.next)
        newPasswordView.configurePasswordElementUI(label: .newPassword , returnKey: UIReturnKeyType.done)
        
        self.currentPasswordView.delegate = self
        self.reTypePasswordView.delegate = self
        self.newPasswordView.delegate = self
    }

    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        
        print(self.currentPasswordView.value ?? "none")
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case self.currentPasswordView:
            self.reTypePasswordView.becomeFirstResponder()
        case self.reTypePasswordView:
            self.newPasswordView.becomeFirstResponder()
        default:
            self.newPasswordView.resignFirstResponder()
        }
    }
}
extension AccountSettingsViewController : UITextFieldDelegate {
    
}
