//
//  AccountDeleteViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 17.06.2021.
//

import UIKit

class AccountDeleteViewController: BaseViewController<AccountDeleteViewModel> {
    
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var deleteButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AccountDeleteViewModel()
        
        title = "Delete Account"

        deleteButton.configureActionButtonUI(title: .delete, bgColor: .deepRed)
        deleteButton.isEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        
        styleNavBar()
        
        confirmTextField.delegate = self
    }

    @IBAction func deleteButtonPressed(_ sender: Any) {
        if confirmTextField.text == "DELETE" {
            viewModel?.deleteAccount(completion: { [self] success in
                if success {
                    dismiss(animated: true, completion: nil)
                    UploadManager.shared.cancelAll()
                    
                    AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication)
                }
            })
        }
    }
    
    @objc
    func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func textFieldValueChanged(_ sender: Any) {
        deleteButton.isEnabled = confirmTextField.text == "DELETE"
    }
    
}

extension AccountDeleteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
