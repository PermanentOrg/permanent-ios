//
//  TrustedStewardViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2023.
//

import Foundation
import UIKit

class TrustedStewardViewController: BaseViewController<LegacyPlanningViewModel> {
    @IBOutlet weak var designateStewardTitleLabel: UILabel!
    @IBOutlet weak var designateStewardDescriptionLabel: UILabel!
    
    @IBOutlet weak var designateStewardNameTextField: UITextField!
    @IBOutlet weak var designateStewardEmailTextField: UITextField!
    @IBOutlet weak var designateStewardSelectionInfoTextView: UITextView!
    @IBOutlet weak var designateStewardEmailVerificationLabel: UILabel!
    @IBOutlet weak var designateStewardInfoTextViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var designateStewardNameView: UIView!
    @IBOutlet weak var designateStewardEmailStackView: UIStackView!
    @IBOutlet weak var designateStewardInfoView: UIView!
    @IBOutlet weak var emailVerificationImageView: UIImageView!
    @IBOutlet weak var inviteUserToPermanentLabel: UILabel!
    @IBOutlet weak var inviteUserToPermanentSwitch: UISwitch!
    @IBOutlet weak var inviteUserToPermanentStackView: UIStackView!
    
    @IBOutlet weak var noteTitleLabel: UILabel!
    @IBOutlet weak var noteDescriptionLabel: UILabel!
    
    private let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.isLoading = { [weak self] loading in
            if loading {
                self?.showSpinner()
            } else {
                self?.hideSpinner()
            }
        }
        
        viewModel?.showError = { [weak self] error in
            if error == .badRequest {
                self?.showAlert(title: .error, message: "Please enter a valid email address that is associated with an existing account.")
            } else {
                self?.showAlert(title: .error, message: .errorMessage)
            }
        }
        
        viewModel?.stewardWasUpdated = { [weak self] result in
            if result {
                self?.dismiss(animated: true, completion: {
                    (self?.viewModel?.stewardWasSaved ?? { _ in })(true)
                })
            }
        }
        
        viewModel?.selectedSteward = nil
        
        setupUI()
        loadSteward()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    private func loadSteward() {
        designateStewardNameTextField.text = viewModel?.selectedSteward?.name
        designateStewardEmailTextField.text = viewModel?.selectedSteward?.email
        if let note = viewModel?.selectedSteward?.note {
            designateStewardSelectionInfoTextView.text = note
        }
    }
    
    private func setupUI() {
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        addDismissKeyboardGesture()
        customizeNavigationController()

        if viewModel?.stewardType == .archive {
            title = "Trusted Steward".localized()
        } else {
            title = "Legacy Contact".localized()
        }
        view.backgroundColor = .backgroundPrimary
        
        customizeDesignateStewardTitleLabel()
        customizeDesignateStewardDescriptionLabel()
        customizeTextFieldElements(textField: [designateStewardNameTextField, designateStewardEmailTextField])
        if viewModel?.stewardType == .archive {
            designateStewardInfoView.isHidden = false
            designateStewardNameView.isHidden = true
            customizeDesignateStewardSelectionInfoLabel()
        } else {
            designateStewardNameView.isHidden = false
            designateStewardInfoView.isHidden = true
        }
        customizeEmailVerificationLabel()
        customizeNoteTitleLabel()
        customizeNoteDescriptionLabel()
        customizeInviteUserToPermanentLabel()
        customizeSeparatorView()
        customizeView(designateStewardNameView)
        customizeView(designateStewardEmailStackView)
        customizeView(designateStewardInfoView)
    }
    
    private func customizeNavigationController() {
        navigationController?.toolbar.backgroundColor = .primary
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .primary
        
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        
        let doneButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(doneButtonTapped))
        doneButton.tintColor = .white
        navigationItem.rightBarButtonItem = doneButton

        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        cancelButton.tintColor = .white
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func customizeDesignateStewardTitleLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17

        var attributedText = NSMutableAttributedString(string: "Designate archive steward".localized(), attributes: [NSAttributedString.Key.kern: -0.3, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        if viewModel?.stewardType == .account {
            attributedText = NSMutableAttributedString(string: "Designate legacy contact".localized(), attributes: [NSAttributedString.Key.kern: -0.3, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        }

        designateStewardTitleLabel.textColor = .primary
        designateStewardTitleLabel.font = TextFontStyle.style41.font
        designateStewardTitleLabel.attributedText = attributedText
    }
    
    private func customizeDesignateStewardDescriptionLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36

        var attributedText = NSMutableAttributedString(string: "In order to designate someone as a steward for your archive, they must have a Permanent.org account.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        if viewModel?.stewardType == .account {
            attributedText = NSMutableAttributedString(string: "Choose someone to be your legacy contact to save your account legacy plan.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        }

        designateStewardDescriptionLabel.textColor = .black
        designateStewardDescriptionLabel.font = TextFontStyle.style39.font
        designateStewardDescriptionLabel.numberOfLines = 0
        designateStewardDescriptionLabel.lineBreakMode = .byWordWrapping
        designateStewardDescriptionLabel.attributedText = attributedText
    }
    
    private func customizeDesignateStewardSelectionInfoLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.26

        let attributedText = NSMutableAttributedString(string: "Thank you for being the steward of my archive. I appreciate you taking care of my legacy when I am gone.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        
        designateStewardSelectionInfoTextView.attributedText = attributedText
        designateStewardSelectionInfoTextView.textAlignment = .left
        designateStewardSelectionInfoTextView.textColor = .black
        designateStewardSelectionInfoTextView.font = TextFontStyle.style45.font
        designateStewardSelectionInfoTextView.backgroundColor = .clear
        
        updateTextViewHeight()
    }
    
    private func customizeNoteTitleLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.91

        let attributedText = NSMutableAttributedString(string: "Note".localized().uppercased(), attributes: [NSAttributedString.Key.kern: 0.8, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        noteTitleLabel.textColor = .darkBlue
        noteTitleLabel.font = TextFontStyle.style30.font
        noteTitleLabel.attributedText = attributedText
    }

    private func customizeTextFieldElements(textField: [UITextField]) {
        let placeholderTextColor = UIColor.lightGray
        let textColor = UIColor.black

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.26

        var attributedPlaceholder = NSMutableAttributedString()
        
        for textField in textField {
            switch textField {
            case designateStewardNameTextField:
                attributedPlaceholder = NSMutableAttributedString(string: "Steward name...".localized(), attributes: [NSAttributedString.Key.foregroundColor: placeholderTextColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])
                break
            case designateStewardEmailTextField:
                attributedPlaceholder = NSMutableAttributedString(string: "Steward email address...".localized(), attributes: [NSAttributedString.Key.foregroundColor: placeholderTextColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])
                break
            default:
                break
            }
            textField.attributedPlaceholder = attributedPlaceholder
            textField.textColor = textColor
            textField.font = TextFontStyle.style8.font
            textField.borderStyle = .none
        }
    }

    private func customizeNoteDescriptionLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36

        var attributedText = NSMutableAttributedString(string: "Your Archive Steward will get an email from Permanent with instructions. Discuss your Legacy Plan first. They'll receive another email when the plan is activated with steps to accept ownership. Add instructions in the note section above.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        if viewModel?.stewardType == .account {
            attributedText = NSMutableAttributedString(string: "Permanent will send an automatic email to your Legacy Contact to inform them that they have been designated to activate your Account Legacy Plan, alongside instructions on how to do so. However, we strongly recommend that you also discuss your Legacy Plan with this person.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        }

        noteDescriptionLabel.textColor = .black
        noteDescriptionLabel.font = TextFontStyle.style39.font
        noteDescriptionLabel.numberOfLines = 0
        noteDescriptionLabel.lineBreakMode = .byWordWrapping
        noteDescriptionLabel.attributedText = attributedText
    }
    
    private func customizeEmailVerificationLabel() {
        designateStewardEmailVerificationLabel.font = TextFontStyle.style12.font
        designateStewardEmailVerificationLabel.textColor = .lightRed
        
        let emailVerificationParagraphStyle = NSMutableParagraphStyle()
        emailVerificationParagraphStyle.lineHeightMultiple = 1.47
        
        let emailVerificationAttributedText = NSMutableAttributedString(string: "User not found in Permanent database.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: emailVerificationParagraphStyle])
        
        designateStewardEmailVerificationLabel.attributedText = emailVerificationAttributedText
    }
    
    private func customizeInviteUserToPermanentLabel() {
        inviteUserToPermanentLabel.textColor = .darkBlue
        inviteUserToPermanentLabel.font = TextFontStyle.style35.font
        
        let inviteUserParagraphStyle = NSMutableParagraphStyle()
        inviteUserParagraphStyle.lineHeightMultiple = 1.17
        
        let inviteUserAttributedText = NSMutableAttributedString(string: "Invite steward to Permanent now?".localized(), attributes: [NSAttributedString.Key.kern: -0.3, NSAttributedString.Key.paragraphStyle: inviteUserParagraphStyle])
        
        inviteUserToPermanentLabel.attributedText = inviteUserAttributedText
        inviteUserToPermanentSwitch.transform = CGAffineTransform(scaleX: 0.77, y: 0.77)
    }
    
    private func customizeSeparatorView() {
        separatorView.alpha = 0.08

        separatorView.layer.backgroundColor = UIColor.middleGray.cgColor
        separatorView.layer.cornerRadius = 2
    }
    
    private func customizeView(_ view: UIView) {
        view.layer.backgroundColor = UIColor.whiteGray.withAlphaComponent(0.5).cgColor
        view.layer.cornerRadius = 2
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.whiteGray.cgColor
    }
    
    func updateTextViewHeight() {
        let fixedWidth = designateStewardSelectionInfoTextView.frame.size.width
        let newSize = designateStewardSelectionInfoTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        if newSize.height <= 132 {
            designateStewardInfoTextViewHeightConstraint.constant = newSize.height
        } else {
            designateStewardInfoTextViewHeightConstraint.constant = 132
        }
    }
    
    @objc func doneButtonTapped() {
        guard let selectedStewardName = designateStewardNameTextField.text else {
            showAlert(title: "Name Required".localized(), message: "Please enter a name.".localized())
            return
        }

        if viewModel?.stewardType == .account && selectedStewardName.isEmpty {
            showAlert(title: "Name Required".localized(), message: "Please enter a name.".localized())
            return
        }
        
        guard let selectedStewardEmail = designateStewardEmailTextField.text, selectedStewardEmail.isNotEmpty else {
            showAlert(title: "Email Required".localized(), message: "Please enter an email address.".localized())
            return
        }
        
        if !selectedStewardEmail.isValidEmail {
            showAlert(title: "Invalid Email".localized(), message: "Please enter a valid email address.".localized())
            return
        }
        
        if viewModel?.selectedSteward != nil {
            viewModel?.updateTrustedSteward(name: selectedStewardName, stewardEmail: selectedStewardEmail, note: designateStewardSelectionInfoTextView.text ?? "")
        } else {
            viewModel?.addSteward(name: selectedStewardName, email: selectedStewardEmail, note: designateStewardSelectionInfoTextView.text ?? "", status: .pending)
        }
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func inviteUserToPermanentTapped(_ sender: Any) {
        
    }
    
    private func updateEmailValidationUI(isValid: Bool) {
        if isValid {
            designateStewardEmailStackView.layer.borderColor = UIColor.clear.cgColor
            designateStewardEmailVerificationLabel.isHidden = true
            inviteUserToPermanentStackView.isHidden = true
        } else {
            designateStewardEmailStackView.layer.borderColor = UIColor.lightRed.cgColor
            designateStewardEmailVerificationLabel.isHidden = false
            inviteUserToPermanentStackView.isHidden = false
        }
    }
}

extension TrustedStewardViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == designateStewardNameTextField {
            designateStewardEmailTextField.becomeFirstResponder()
        } else if textField == designateStewardEmailTextField {
            if let email = textField.text, email.isValidEmail {
                updateEmailValidationUI(isValid: email.isValidEmail)
            }
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == designateStewardEmailTextField {
            if let email = textField.text, email.isValidEmail {
                updateEmailValidationUI(isValid: email.isValidEmail)
            }
        }
    }
}

extension TrustedStewardViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
    }
}
