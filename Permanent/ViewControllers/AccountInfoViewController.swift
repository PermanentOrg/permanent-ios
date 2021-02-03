//
//  AccountInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import UIKit

class AccountInfoViewController: BaseViewController<InfoViewModel> {


    @IBOutlet var accountNameView: InputTextWithLabelElementViewViewController!
    @IBOutlet var primaryEmailView: InputTextWithLabelElementViewViewController!
    @IBOutlet var mobileEmailView: InputTextWithLabelElementViewViewController!
    @IBOutlet var addressView: InputTextWithLabelElementViewViewController!
    @IBOutlet var cityView: InputTextWithLabelElementViewViewController!
    @IBOutlet var stateView: InputTextWithLabelElementViewViewController!
    @IBOutlet var postalCodeView: InputTextWithLabelElementViewViewController!
    @IBOutlet var countryView: InputTextWithLabelElementViewViewController!
    @IBOutlet var contentUpdateButton: RoundedButton!

    override func viewDidLoad (){
        super.viewDidLoad()
        viewModel = InfoViewModel()
        initUI()
    }

    private func initUI() {
        
        title = .accountInfo
        view.backgroundColor = .white
        
        accountNameView.configureElementUI(label: .accountName, returnKey: UIReturnKeyType.next)
        primaryEmailView.configureElementUI(label: .primaryEmail, returnKey: UIReturnKeyType.next)
        mobileEmailView.configureElementUI(label: .mobilePhone, returnKey: UIReturnKeyType.next)
        addressView.configureElementUI(label: .address, returnKey: UIReturnKeyType.next)
        cityView.configureElementUI(label: .city, returnKey: UIReturnKeyType.next)
        stateView.configureElementUI(label: .stateOrRegion, returnKey: UIReturnKeyType.next)
        postalCodeView.configureElementUI(label: .postalcode, returnKey: UIReturnKeyType.next)
        countryView.configureElementUI(label: .country, returnKey: UIReturnKeyType.done)
        contentUpdateButton.configureActionButtonUI(title: .save)
        
        accountNameView.delegate = self
        primaryEmailView.delegate = self
        mobileEmailView.delegate = self
        addressView.delegate = self
        cityView.delegate = self
        stateView.delegate = self
        postalCodeView.delegate = self
        countryView.delegate = self
        
        getUserDetails()
    }
    
    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptValuesChange()
    }
    
    func getUserDetails() {

        let groupAccountInfo = DispatchGroup()
        
        showSpinner()
        guard
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            return
        }
            groupAccountInfo.enter()
            viewModel?.getNewCsrf(then: { _ in
                DispatchQueue.main.async {
                    self.viewModel!.apiData["accountId"] = String(accountID)
                   // self.viewModel?.accountID = String(accountID)
                    groupAccountInfo.leave()
                }
            })


        groupAccountInfo.notify(queue: DispatchQueue.global()) {
            guard
                let accountID: String = self.viewModel?.apiData["accountId"],
                let csrf: String = self.viewModel?.apiData["csrf"] else {
                return
            }
            self.viewModel?.getUserData(with: accountID, csrf: csrf, then: { status in
                switch status {
                case true:
                    self.updateUserDetailsFields()
                    print("test ",(self.viewModel?.apiData["primaryEmail"])!)
                case false:
                    self.showErrorAlert(message: .errorMessage)
                    break
                }
            })
            DispatchQueue.main.async {
            self.hideSpinner()
            }
        }
        
    }
    func updateUserDetailsFields() {
        self.primaryEmailView.setTextFieldValue(text: self.viewModel?.apiData["primaryEmail"] ?? "")
        self.accountNameView.setTextFieldValue(text: self.viewModel?.apiData["fullName"] ?? "")
        self.addressView.setTextFieldValue(text: self.viewModel?.apiData["address"] ?? "")
        self.cityView.setTextFieldValue(text: self.viewModel?.apiData["city"] ?? "")
        self.stateView.setTextFieldValue(text: self.viewModel?.apiData["state"] ?? "")
        self.postalCodeView.setTextFieldValue(text: self.viewModel?.apiData["zip"] ?? "")
        self.countryView.setTextFieldValue(text: self.viewModel?.apiData["country"] ?? "")
        self.mobileEmailView.setTextFieldValue(text: self.viewModel?.apiData["primaryPhone"] ?? "")
    }
    
    func attemptValuesChange() {
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case accountNameView.textField:
            primaryEmailView.textField.becomeFirstResponder()
        case primaryEmailView.textField:
            mobileEmailView.textField.becomeFirstResponder()
        case mobileEmailView.textField:
            addressView.textField.becomeFirstResponder()
        case addressView.textField:
            cityView.textField.becomeFirstResponder()
        case cityView.textField:
            stateView.textField.becomeFirstResponder()
        case stateView.textField:
            postalCodeView.textField.becomeFirstResponder()
        case postalCodeView.textField:
            countryView.textField.becomeFirstResponder()
        default:
            countryView.textField.resignFirstResponder()
        }
    }
}

extension AccountInfoViewController: UITextFieldDelegate {
    
}
