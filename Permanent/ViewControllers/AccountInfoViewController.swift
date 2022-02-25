//
//  AccountInfoViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.01.2021.
//

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
    }

    private func initUI() {
        title = .accountInfo
        view.backgroundColor = .white
        
        accountNameView.configureElementUI(label: .accountName, returnKey: UIReturnKeyType.done)
        primaryEmailView.configureElementUI(label: .primaryEmail, returnKey: UIReturnKeyType.done)
        mobilePhoneView.configureElementUI(label: .mobilePhone, returnKey: UIReturnKeyType.done, keyboardType: .numbersAndPunctuation)
        addressView.configureElementUI(label: "Address Line 1".localized(), returnKey: UIReturnKeyType.done)
        addressView2.configureElementUI(label: "Address Line 2".localized(), returnKey: UIReturnKeyType.done)
        cityView.configureElementUI(label: .city, returnKey: UIReturnKeyType.done)
        stateView.configureElementUI(label: .stateOrRegion, returnKey: UIReturnKeyType.done)
        postalCodeView.configureElementUI(label: .postalcode, returnKey: UIReturnKeyType.done)
        countryView.configureElementUI(label: .country, returnKey: UIReturnKeyType.done)
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
        textField.resignFirstResponder()
        
        switch textField {
        case postalCodeView.textField, countryView.textField, cityView.textField, stateView.textField:
            let point = CGPoint.zero
            scrollView.setContentOffset(point, animated: true)
            
        default:
            break
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let changePosition: [CGFloat] = [view.frame.height / 10, view.frame.height / 7]
        (textField as? TextField)?.toggleBorder(active: true)
        
        let point: CGPoint
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
            point = CGPoint.zero
        }
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}
