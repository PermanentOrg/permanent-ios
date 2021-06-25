//
//  AccountInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

import UIKit

class AccountInfoViewController: BaseViewController<InfoViewModel> {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var accountNameView: InputTextWithLabelElementViewViewController!
    @IBOutlet var primaryEmailView: InputTextWithLabelElementViewViewController!
    @IBOutlet var mobilePhoneView: InputTextWithLabelElementViewViewController!
    @IBOutlet var addressView: InputTextWithLabelElementViewViewController!
    @IBOutlet var cityView: InputTextWithLabelElementViewViewController!
    @IBOutlet var stateView: InputTextWithLabelElementViewViewController!
    @IBOutlet var postalCodeView: InputTextWithLabelElementViewViewController!
    @IBOutlet var countryView: InputTextWithLabelElementViewViewController!
    @IBOutlet var contentUpdateButton: RoundedButton!
    @IBOutlet weak var deleteAccountButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = InfoViewModel()
        initUI()
    }

    private func initUI() {
        title = .accountInfo
        view.backgroundColor = .white
        
        accountNameView.configureElementUI(label: .accountName, returnKey: UIReturnKeyType.next)
        primaryEmailView.configureElementUI(label: .primaryEmail, returnKey: UIReturnKeyType.next)
        mobilePhoneView.configureElementUI(label: .mobilePhone, returnKey: UIReturnKeyType.next, keyboardType: .numbersAndPunctuation)
        addressView.configureElementUI(label: .address, returnKey: UIReturnKeyType.next)
        cityView.configureElementUI(label: .city, returnKey: UIReturnKeyType.next)
        stateView.configureElementUI(label: .stateOrRegion, returnKey: UIReturnKeyType.next)
        postalCodeView.configureElementUI(label: .postalcode, returnKey: UIReturnKeyType.next)
        countryView.configureElementUI(label: .country, returnKey: UIReturnKeyType.done)
        contentUpdateButton.configureActionButtonUI(title: .save)
        deleteAccountButton.configureActionButtonUI(title: "Delete Account".localized(), bgColor: .deepRed)
        
        accountNameView.delegate = self
        primaryEmailView.delegate = self
        mobilePhoneView.delegate = self
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
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        let deleteVC = UIViewController.create(withIdentifier: .accountDelete, from: .settings)
        let navigationController = NavigationController(rootViewController: deleteVC)
        present(navigationController, animated: true, completion: nil)
    }
    
    func getUserDetails() {
        let groupAccountInfo = DispatchGroup()
        
        showSpinner()
        guard
            let accountID: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
        else {
            return
        }
        groupAccountInfo.enter()
        viewModel?.getNewCsrf(then: { _ in
            DispatchQueue.main.async {
                self.viewModel!.accountId = String(accountID)
                groupAccountInfo.leave()
            }
        })

        groupAccountInfo.notify(queue: DispatchQueue.global()) {
            guard
                let accountID: String = self.viewModel?.accountId,
                let csrf: String = self.viewModel?.actualCsrf
            else {
                return
            }
            self.viewModel?.getUserData(with: accountID, csrf: csrf, then: { status in
                switch status {
                case true:
                    self.updateUserDetailsFields()
                case false:
                    self.showErrorAlert(message: .errorMessage)
                }
            })
            DispatchQueue.main.async {
                self.hideSpinner()
            }
        }
    }
    
    func attemptValuesChange() {
        showSpinner()
        viewModel?.getValuesFromTextFieldValue(receivedData: (accountNameView.value,
                                                              primaryEmailView.value,
                                                              mobilePhoneView.value,
                                                              addressView.value,
                                                              cityView.value,
                                                              stateView.value,
                                                              postalCodeView.value,
                                                              countryView.value))

        guard
            let accountID: String = viewModel?.accountId,
            let csrf: String = viewModel?.actualCsrf,
            let userData: UpdateUserData = viewModel?.userData
        else {
            showAlert(title: .error, message: .errorMessage)
            return
        }
        viewModel?.updateUserData(with: accountID, csrf: csrf, userData: userData, then: { status in
            switch status {
            case .success(message: let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight,
                                                     title: message!)
                }
            case .error(message: let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.showAlert(title: .error, message: message)
                }
            }
            
        })
    }
    
    func updateUserDetailsFields() {
        primaryEmailView.setTextFieldValue(text: viewModel?.userData.primaryEmail ?? "")
        accountNameView.setTextFieldValue(text: viewModel?.userData.fullName ?? "")
        addressView.setTextFieldValue(text: viewModel?.userData.address ?? "")
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
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        switch textField {
        case accountNameView.textField:
            primaryEmailView.textField.becomeFirstResponder()
        case primaryEmailView.textField:
            mobilePhoneView.textField.becomeFirstResponder()
        case mobilePhoneView.textField:
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
            let point = CGPoint(x: 0, y: 0)
            scrollView.setContentOffset(point, animated: true)
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        var point = CGPoint(x: 0, y: 0)
        let changePosition: [CGFloat] = [view.frame.height/10,view.frame.height/7]
        (textField as? TextField)?.toggleBorder(active: true)
        switch textField {
        case cityView.textField:
            point = CGPoint(x: 0, y: textField.frame.origin.y + changePosition[0])
        case stateView.textField:
            point = CGPoint(x: 0, y: textField.frame.origin.y + changePosition[0])
        case postalCodeView.textField:
            point = CGPoint(x: 0, y: textField.frame.origin.y + changePosition[1])
        case countryView.textField:
            point = CGPoint(x: 0, y: textField.frame.origin.y + changePosition[1])
        default:
            point = CGPoint(x: 0, y: 0)
        }
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}
