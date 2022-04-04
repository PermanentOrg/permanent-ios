//
//  DonateViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 29.03.2022.
//

import UIKit
import StripeApplePay
import PassKit

class DonateViewController: BaseViewController<FilesViewModel> {
    
    @IBOutlet weak var donateStackBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var amountContainerView: UIView!
    @IBOutlet weak var donateTextField: UITextField!
    @IBOutlet weak var endowmentLabel: UILabel!
    @IBOutlet weak var paymentView: UIView!
    let applePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: .black)
    
    static var invalidCharacterSet: CharacterSet = {
        var characterSet = CharacterSet.decimalDigits
        characterSet.insert(charactersIn: ".")
        return characterSet.inverted
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        amountContainerView.layer.borderColor = UIColor.systemOrange.cgColor
        amountContainerView.layer.borderWidth = 1
        amountContainerView.layer.cornerRadius = 5
        amountContainerView.clipsToBounds = true
        
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.addTarget(self, action: #selector(applePayButtonPressed(_:)), for: .touchUpInside)
        paymentView.addSubview(applePayButton)
        
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
        
        NSLayoutConstraint.activate([
            applePayButton.topAnchor.constraint(equalTo: paymentView.topAnchor, constant: 0),
            applePayButton.leadingAnchor.constraint(equalTo: paymentView.leadingAnchor, constant: 0),
            applePayButton.trailingAnchor.constraint(equalTo: paymentView.trailingAnchor, constant: -0),
            applePayButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
        
        donateStackBottomConstraint.constant = endFrame.cgRectValue.height
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        
        donateStackBottomConstraint.constant = 0
        
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
        if textField.text?.count == 0 && string.range(of: ".")?.isEmpty == false {
            shouldChangeCharacters = false
        }

        guard let textAfterReplacing = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return false
        }
        
        let selectedAmount = Double(textAfterReplacing)
        
        let storageSize = Int(floor((selectedAmount ?? 0) / 10))
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
        setAmountSelected(atIndex: -1)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == donateTextField else { return }
        
        donateTextField.layer.borderColor = UIColor.black.cgColor
    }
}

extension DonateViewController: ApplePayContextDelegate {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        var req = URLRequest(url: URL(string: "https://api.stripe.com/v1/payment_intents")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("Basic ", forHTTPHeaderField: "Authorization")
        req.httpBody = "amount=\(donateTextField.text!)&currency=usd".data(using: .utf8)
        
        let dt = URLSession.shared.dataTask(with: req) { data, urlresponse, error in
            if let data = data {
                let jsonObj = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
                 
                let clientSecret = jsonObj["client_secret"] as? String ?? ""
                completion(clientSecret, nil)
            }
        }
        dt.resume()
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
