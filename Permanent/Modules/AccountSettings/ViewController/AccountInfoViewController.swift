//
//  AccountInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import SwiftUI
import UIKit

class AccountInfoViewController: BaseViewController<InfoViewModel> {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountNameView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var primaryEmailView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var mobilePhoneView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var addressView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var addressView2: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var cityView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var stateView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var postalCodeView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var countryView: InputTextWithLabelElementViewViewController!
    @IBOutlet weak var contentUpdateButton: RoundedButton!
    @IBOutlet weak var deleteAccountButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = InfoViewModel()
        initUI()
        viewModel?.trackEvents(action: AccountEventAction.openLoginInfo)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let inset = keyboardFrame.height - view.safeAreaInsets.bottom
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = inset
            self.scrollView.verticalScrollIndicatorInsets.bottom = inset
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    @objc private func moveToNextFromPhone() {
        addressView.textField?.becomeFirstResponder()
    }

    private func initUI() {
        title = .accountInfo
        view.backgroundColor = .white
        
        accountNameView.configureElementUI(label: .accountName, returnKey: .next)
        primaryEmailView.configureElementUI(label: .primaryEmail, returnKey: .next)
        mobilePhoneView.configureElementUI(label: .mobilePhone, returnKey: .next, keyboardType: .phonePad)
        addressView.configureElementUI(label: "Address Line 1".localized(), returnKey: .next)
        addressView2.configureElementUI(label: "Address Line 2".localized(), returnKey: .next)
        cityView.configureElementUI(label: .city, returnKey: .next)
        stateView.configureElementUI(label: .stateOrRegion, returnKey: .next)
        postalCodeView.configureElementUI(label: .postalcode, returnKey: .next)
        countryView.configureElementUI(label: .country, returnKey: .done)
        contentUpdateButton.configureActionButtonUI(title: .save)
        deleteAccountButton.configureActionButtonUI(title: "Delete Account".localized(), bgColor: .deepRed)
        
        accountNameView.delegate = self
        primaryEmailView.delegate = self
        mobilePhoneView.delegate = self
        addressView.delegate = self
        addressView2.delegate = self
        cityView.delegate = self
        stateView.delegate = self
        postalCodeView.delegate = self
        countryView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)

        getUserDetails()
        
        
        //toolbar for having a next button on phone number introduction
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(moveToNextFromPhone))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [spacer, nextButton]
        mobilePhoneView.textField?.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptValuesChange()
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard let deleteVC = UIViewController.create(withIdentifier: .accountDelete, from: .settings) as? AccountDeleteViewController else { return }
        let navigationController = NavigationController(rootViewController: deleteVC)
        present(navigationController, animated: true, completion: nil)
        
        deleteVC.deleteAccountClosure = { [weak self] in
            self?.parent?.dismiss(animated: false, completion: {
                AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication, showRegisterView: true)
            })
        }
    }
    
    func getUserDetails() {
        showSpinner()
        
        self.viewModel?.getUserData(then: { status in
            self.hideSpinner()
            
            switch status {
            case .success(message: _):
                self.updateUserDetailsFields()
                
            case .error(message: let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func attemptValuesChange() {
        showSpinner()
        viewModel?.getValuesFromTextFieldValue(receivedData: (
            accountNameView.value,
            primaryEmailView.value,
            mobilePhoneView.value,
            addressView.value,
            addressView2.value,
            cityView.value,
            stateView.value,
            postalCodeView.value,
            countryView.value
        ))

        guard let userData: UpdateUserData = viewModel?.userData else {
            showAlert(title: .error, message: .errorMessage)
            return
        }
        
        viewModel?.updateUserData(userData, then: { status in
            switch status {
            case .success(message: let message):
                self.hideSpinner()
                self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: message!)
                
            case .error(message: let message):
                self.hideSpinner()
                self.showAlert(title: .error, message: message)
            }
        })
    }
    
    func updateUserDetailsFields() {
        primaryEmailView.setTextFieldValue(text: viewModel?.userData.primaryEmail ?? "")
        accountNameView.setTextFieldValue(text: viewModel?.userData.fullName ?? "")
        addressView.setTextFieldValue(text: viewModel?.userData.address ?? "")
        addressView2.setTextFieldValue(text: viewModel?.userData.address2 ?? "")
        cityView.setTextFieldValue(text: viewModel?.userData.city ?? "")
        stateView.setTextFieldValue(text: viewModel?.userData.state ?? "")
        postalCodeView.setTextFieldValue(text: viewModel?.userData.zip ?? "")
        countryView.setTextFieldValue(text: viewModel?.userData.country ?? "")
        mobilePhoneView.setTextFieldValue(text: viewModel?.userData.primaryPhone ?? "")
    }
}

extension AccountInfoViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == mobilePhoneView.textField {
            guard let text = textField.text else { return false }
            let newString = (text as NSString).replacingCharacters(in: range, with: string)
            textField.text = viewModel?.format(with: "+ZZZZZZZZZZZ", phone: newString)
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = [
            accountNameView.textField,
            primaryEmailView.textField,
            mobilePhoneView.textField,
            addressView.textField,
            addressView2.textField,
            cityView.textField,
            stateView.textField,
            postalCodeView.textField,
            countryView.textField
        ]
        if let index = fields.firstIndex(of: textField), index < fields.count - 1 {
            fields[index + 1]?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? PETextField)?.toggleBorder(active: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let fieldFrame = self.scrollView.convert(textField.bounds, from: textField)
            let visibleRect = fieldFrame.insetBy(dx: 0, dy: -16)
            self.scrollView.scrollRectToVisible(visibleRect, animated: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? PETextField)?.toggleBorder(active: false)
    }
}
