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
    @IBOutlet var cityView: SmallInputTextWithLabelViewController!
    @IBOutlet var stateView: SmallInputTextWithLabelViewController!
    @IBOutlet var postalCodeView: SmallInputTextWithLabelViewController!
    @IBOutlet var countryView: SmallInputTextWithLabelViewController!
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
    }
    
    @IBAction func pressedUpdateButton(_ sender: RoundedButton) {
        attemptValuesChange()
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
