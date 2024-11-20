//
//  DonateViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 29.03.2022.
//

import UIKit
import StripeApplePay
import PassKit

class DonateViewController: BaseViewController<DonateViewModel> {
    @IBOutlet weak var vfxView: UIVisualEffectView!
    @IBOutlet weak var amountContainerView: UIView!
    @IBOutlet weak var donateTextField: UITextField!
    @IBOutlet weak var endowmentLabel: UILabel!
    @IBOutlet weak var paymentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contextLabel: UILabel!
    
    let applePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)
    
    static var invalidCharacterSet: CharacterSet = {
        var characterSet = CharacterSet.decimalDigits
        characterSet.insert(charactersIn: ".")
        return characterSet.inverted
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = DonateViewModel()

        title = "Storage".localized()
        setTextContent()
        
        amountContainerView.layer.borderColor = UIColor.systemOrange.cgColor
        amountContainerView.layer.borderWidth = 1
        amountContainerView.layer.cornerRadius = 5
        amountContainerView.clipsToBounds = true
        
        let currencyLabel = UILabel(frame: CGRect.zero)
        currencyLabel.text = "  $ "
        currencyLabel.sizeToFit()
        donateTextField.leftView = currencyLabel
        donateTextField.leftViewMode = .always
        donateTextField.layer.borderColor = UIColor.black.cgColor
        donateTextField.layer.borderWidth = 1
        donateTextField.layer.cornerRadius = 5
        donateTextField.clipsToBounds = true
        donateTextField.delegate = self
        
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.cornerRadius = 5
        applePayButton.addTarget(self, action: #selector(applePayButtonPressed(_:)), for: .touchUpInside)
        paymentView.addSubview(applePayButton)
        
        NSLayoutConstraint.activate([
            applePayButton.topAnchor.constraint(equalTo: paymentView.topAnchor, constant: 5),
            applePayButton.leadingAnchor.constraint(equalTo: paymentView.leadingAnchor, constant: 0),
            applePayButton.trailingAnchor.constraint(equalTo: paymentView.trailingAnchor, constant: 0),
            applePayButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setTextContent() {
        titleLabel.text = "NEED MORE STORAGE?".localized()
        titleLabel.font = TextFontStyle.style31.font
        titleLabel.textColor = .dustyGray
        titleLabel.textAlignment = .left

        contextLabel.text = "Purchase as little or as much at a time, anytime you'd like.".localized()
        contextLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contextLabel.font = TextFontStyle.style3.font
        contextLabel.textColor = .darkBlue
        contextLabel.textAlignment = .left
        contextLabel.numberOfLines = 0
    }
    
    func amountView(atIndex index: Int) -> UIView {
        return amountContainerView.subviews[index]
    }
    
    func amountLabel(atIndex index: Int) -> UILabel? {
        return amountContainerView.subviews[index].subviews.first(where: { $0 is UILabel }) as? UILabel
    }
    
    func amountButton(atIndex index: Int) -> UIButton? {
        return amountContainerView.subviews[index].subviews.first(where: { $0 is UIButton }) as? UIButton
    }
    
    func setAmountSelected(atIndex selectedIndex: Int) {
        for idx in 0...2 {
            if idx == selectedIndex {
                amountLabel(atIndex: idx)?.textColor = .white
                amountView(atIndex: idx).backgroundColor = .systemOrange
            } else {
                amountLabel(atIndex: idx)?.textColor = .black
                amountView(atIndex: idx).backgroundColor = .white
            }
        }
    }
    
    @IBAction func firstAmountButtonPressed(_ sender: Any) {
        setAmountSelected(atIndex: 0)
        donateTextField.text = "10"
        endowmentLabel.text = "Endow 1 GB".localized()
    }
    
    @IBAction func secondAmountButtonPressed(_ sender: Any) {
        setAmountSelected(atIndex: 1)
        donateTextField.text = "20"
        endowmentLabel.text = "Endow 2 GB".localized()
    }
    
    @IBAction func thirdAmountButtonPressed(_ sender: Any) {
        setAmountSelected(atIndex: 2)
        donateTextField.text = "50"
        endowmentLabel.text = "Endow 5 GB".localized()
    }
    
    @objc func applePayButtonPressed(_ sender: Any) {
        let amount = NSDecimalNumber(string: donateTextField.text)
        guard amount != 0 else {
            showErrorAlert(message: "Invalid amount selected".localized())
            return
        }
        
        let merchantIdentifier = "merchant.org.permanent.permanentarchive"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")
        
        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Permanent Legacy Foundation", amount: amount)
        ]
        
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay()
        } else {
            showErrorAlert(message: "There is a problem with the ApplePay configuration".localized())
        }
    }
    
    // MARK: - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyBoardInfo = notification.userInfo,
            let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
}

extension DonateViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == donateTextField else { return true }
        
        var shouldChangeCharacters = true
        
        // Do not allow characters other than decimals and dot
        if string.rangeOfCharacter(from: Self.invalidCharacterSet)?.isEmpty == false {
            shouldChangeCharacters = false
        }
        
        // Do not allow two dots
        if textField.text?.range(of: ".")?.isEmpty == false && string.range(of: ".")?.isEmpty == false {
            shouldChangeCharacters = false
        }

        // Do not allow dot as first character
        if textField.text?.isEmpty == false && string.range(of: ".")?.isEmpty == false {
            shouldChangeCharacters = false
        }

        guard let textAfterReplacing = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return false
        }
        
        // Do not allow more than 10000$
        if let selectedAmount = Double(textAfterReplacing), selectedAmount > 10000 {
            return false
        }
        
        let selectedAmount = Double(textAfterReplacing) ?? 0
        
        let storageSize = viewModel!.storageSizeForAmount(selectedAmount)
        endowmentLabel.text = "Endow \(storageSize) GB".localized()
        
        switch selectedAmount {
        case 10: setAmountSelected(atIndex: 0)
            
        case 20: setAmountSelected(atIndex: 1)
            
        case 50: setAmountSelected(atIndex: 2)
            
        default: setAmountSelected(atIndex: -1)
        }
        
        return shouldChangeCharacters
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField == donateTextField else { return true}
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField == donateTextField else { return }
        
        donateTextField.layer.borderColor = UIColor.systemOrange.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == donateTextField else { return }
        
        donateTextField.layer.borderColor = UIColor.black.cgColor
    }
}

// MARK: - ApplePayContextDelegate
extension DonateViewController: ApplePayContextDelegate {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let selectedAmount = Int(floor((Double(donateTextField.text!) ?? 0) * 100))
        
        viewModel?.createPaymentIntent(amount: selectedAmount, { clientSecret in
            completion(clientSecret, nil)
        })
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            showAlert(title: "Thank you!".localized(), message: "Your donation was successful!".localized())
        case .error:
            showErrorAlert(message: .errorMessage)
            
        case .userCancellation:
            break
        }
    }
}
