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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vfxView: UIVisualEffectView!
    @IBOutlet weak var donateStackBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var amountContainerView: UIView!
    @IBOutlet weak var donateTextField: UITextField!
    @IBOutlet weak var endowmentLabel: UILabel!
    @IBOutlet weak var paymentView: UIView!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    
    let applePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: .black)
    
    static var invalidCharacterSet: CharacterSet = {
        var characterSet = CharacterSet.decimalDigits
        characterSet.insert(charactersIn: ".")
        return characterSet.inverted
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = DonateViewModel()

        title = "Storage".localized()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: vfxView.frame.height - 50, right: 0)
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
    
    @IBAction func anonymousSwitchValueChanged(_ sender: Any) {
        viewModel?.isAnonymous = anonymousSwitch.isOn
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
        if textField.text?.isEmpty == false && string.range(of: ".")?.isEmpty == false {
            shouldChangeCharacters = false
        }

        guard let textAfterReplacing = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            return false
        }
        
        let selectedAmount = Double(textAfterReplacing)
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

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DonateViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "donateInfoCell", for: indexPath)
        
        switch indexPath.section {
        case 1:
            cell.textLabel?.text = "Permanence means no subscriptions; a one-time payment for dedicated storage that preserves your most precious memories and an institution that will be there to protect the digital legacy of all people for all time.".localized()
            
        case 2:
            cell.textLabel?.text = "We are leveraging the same funding models used by museums, libraries, and universities for centuries. As a public charity, we can pool all our one-time storage fees into an endowment. We use income generated from this tax-exempt investment fund to pay our ongoing operations and storage costs, in perpetuity.".localized()
            
        case 3:
            cell.textLabel?.text = "Today, our daily operations are supported by our founder and board chair, Mr. Dean Drako. As we grow our endowment through donations and storage contributions, the returns on that investment will gradually replace his contributions until we are fully independent.".localized()
            
        case 4:
            cell.textLabel?.text = "No matter how you found us, we welcome all people to join our movement to democratize permanence and preserve the digital legacy of all people. Choosing Permanent.org isn’t only good for you, it’s a vote for better consumer technology options. Every storage fee donation is also a gift to the nonprofit organizations we through in our byte for byte program.".localized()
            
        default: break
        }
        cell.textLabel?.font = TextFontStyle.style8.font
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 16, y: 8, width: view.frame.width - 32, height: 22))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.font = TextFontStyle.style3.font
        label.textColor = .primary
        
        view.addSubview(label)
        
        switch section {
        case 0:
            label.frame = CGRect(x: 16, y: 16, width: view.frame.width - 32, height: 23)
            label.font = TextFontStyle.style33.font
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.text = "Become a Founding Supporter".localized()
            
            let secondaryLabel = UILabel(frame: CGRect(x: 16, y: label.frame.maxY, width: view.frame.width - 32, height: 22))
            secondaryLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            secondaryLabel.font = TextFontStyle.style4.font
            secondaryLabel.textColor = .primary
            secondaryLabel.textAlignment = .center
            secondaryLabel.adjustsFontSizeToFitWidth = true
            secondaryLabel.minimumScaleFactor = 0.5
            secondaryLabel.text = "Back the new paradigm for cloud storage".localized()
            view.addSubview(secondaryLabel)
            
        case 1:
            label.text = "Our goal is permanence.".localized()
            
        case 2:
            label.text = "How is that possible?".localized()
            
        case 3:
            label.text = "So how does Permanent work now?".localized()
            
        case 4:
            label.text = "It's a win-win for our digital future.".localized()
            
        default: break
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 80 : 30
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
