//
//  AccountDeleteViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 17.06.2021.
//

import UIKit
import SwiftUI

class AccountDeleteViewController: BaseViewController<AccountDeleteViewModel> {
    var deleteAccountClosure: (() -> Void)?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var deleteButton: RoundedButton!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AccountDeleteViewModel()
        
        title = "Delete Account"

        deleteButton.configureActionButtonUI(title: "Delete Account".localized(), bgColor: .deepRed)
        deleteButton.isEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        
        styleNavBar()
        
        confirmTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Actions
    @IBAction func deleteButtonPressed(_ sender: Any) {
        if confirmTextField.text == "DELETE" {
            showSpinner()
            viewModel?.deletePushToken(then: { [weak self] status in
                self?.viewModel?.deleteAccount(completion: { [weak self] success in
                    if success {
                        self?.hideSpinner()
                        UploadManager.shared.cancelAll()

                        self?.dismiss(animated: false) {
                            self?.deleteAccountClosure?()
                            NotificationCenter.default.post(name: AccountDeleteViewModel.accountDeleteSuccessNotification, object: self)
                        }
                    }
                })
            })
        }
    }
    
    @objc
    func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func learnMoreButtonPressed(_ sender: Any) {
        guard let url = URL(string: "https://desk.zoho.com/portal/permanent/en/kb/articles/how-to-delete-an-archive") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func textFieldValueChanged(_ sender: Any) {
        deleteButton.isEnabled = confirmTextField.text == "DELETE"
    }
    
    // MARK: - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let scrollView = scrollView,
            let keyBoardInfo = notification.userInfo,
            let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let window = scrollView.window
        else { return }
        
        let keyBoardFrame = window.convert(endFrame.cgRectValue, to: scrollView.superview)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardFrame.height, right: 0)
        UIView.commitAnimations()
        scrollView.scrollRectToVisible(deleteButton.frame, animated: true)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        var tableInsets = scrollView.contentInset
        tableInsets.bottom = 0
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        scrollView.contentInset = tableInsets
        UIView.commitAnimations()
    }
}

extension AccountDeleteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
