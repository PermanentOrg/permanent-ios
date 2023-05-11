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
    @IBOutlet weak var designateStewardSelectionInfoLabel: UILabel!
    @IBOutlet weak var designateStewardEmailVerificationLabel: UILabel!
    
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
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        addDismissKeyboardGesture()
        customizeNavigationController()

        title = "Trusted Steward".localized()
        view.backgroundColor = .backgroundPrimary
        
        customizeDesignateStewardTitleLabel()
        customizeDesignateStewardDescriptionLabel()
        
        customizeDesignateStewardNameTextField()
        customizeDesignateStewardEmailTextField()
        customizeDesignateStewardSelectionInfoLabel()
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
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        doneButton.tintColor = .white
        navigationItem.rightBarButtonItem = doneButton

        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        cancelButton.tintColor = .white
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    private func customizeDesignateStewardTitleLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17

        let attributedText = NSMutableAttributedString(string: "Designate archive Legacy steward".localized(), attributes: [NSAttributedString.Key.kern: -0.3, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        designateStewardTitleLabel.textColor = .primary
        designateStewardTitleLabel.font = Text.style41.font
        designateStewardTitleLabel.attributedText = attributedText
    }
    
    private func customizeDesignateStewardDescriptionLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36

        let attributedText = NSMutableAttributedString(string: "In order to designate someone as a steward for your archive, they must have a Permanent.org account.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        designateStewardDescriptionLabel.textColor = .black
        designateStewardDescriptionLabel.font = Text.style39.font
        designateStewardDescriptionLabel.numberOfLines = 0
        designateStewardDescriptionLabel.lineBreakMode = .byWordWrapping
        designateStewardDescriptionLabel.attributedText = attributedText
    }
    
    private func customizeDesignateStewardSelectionInfoLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.26

        let attributedText = NSMutableAttributedString(string: "Thank you for being the steward of my archive. I appreciate you taking care of my legacy when I am gone. Please do the following things to my archive when I am gone.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        designateStewardSelectionInfoLabel.textColor = .black
        designateStewardSelectionInfoLabel.font = Text.style45.font
        designateStewardSelectionInfoLabel.numberOfLines = 0
        designateStewardSelectionInfoLabel.lineBreakMode = .byWordWrapping
        designateStewardSelectionInfoLabel.attributedText = attributedText
    }
    
    private func customizeNoteTitleLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.91

        let attributedText = NSMutableAttributedString(string: "Note".localized().uppercased(), attributes: [NSAttributedString.Key.kern: 0.8, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        noteTitleLabel.textColor = .darkBlue
        noteTitleLabel.font = Text.style30.font
        noteTitleLabel.attributedText = attributedText
    }
    
    private func customizeDesignateStewardNameTextField() {
        let placeholderTextColor = UIColor.lightGray
        let textColor = UIColor.black

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.26

        let attributedPlaceholder = NSMutableAttributedString(string: "Steward name...", attributes: [NSAttributedString.Key.foregroundColor: placeholderTextColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        designateStewardNameTextField.textColor = textColor
        designateStewardNameTextField.font = Text.style11.font
        designateStewardNameTextField.attributedPlaceholder = attributedPlaceholder
        designateStewardNameTextField.borderStyle = .none
    }

    private func customizeDesignateStewardEmailTextField() {
        let placeholderTextColor = UIColor.lightGray
        let textColor = UIColor.black

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.26

        let attributedPlaceholder = NSMutableAttributedString(string: "Steward email address...", attributes: [NSAttributedString.Key.foregroundColor: placeholderTextColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        designateStewardEmailTextField.textColor = textColor
        designateStewardEmailTextField.font = Text.style8.font
        designateStewardEmailTextField.attributedPlaceholder = attributedPlaceholder
        designateStewardEmailTextField.borderStyle = .none
    }

    private func customizeNoteDescriptionLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.36

        let attributedText = NSMutableAttributedString(string: "Your Archive Steward will get an email from Permanent with instructions. Discuss your Legacy Plan first. They'll receive another email when the plan is activated with steps to accept ownership. Add instructions in the note section above.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        noteDescriptionLabel.textColor = .black
        noteDescriptionLabel.font = Text.style39.font
        noteDescriptionLabel.numberOfLines = 0
        noteDescriptionLabel.lineBreakMode = .byWordWrapping
        noteDescriptionLabel.attributedText = attributedText
    }
    
    private func customizeEmailVerificationLabel() {
        designateStewardEmailVerificationLabel.font = Text.style12.font
        designateStewardEmailVerificationLabel.textColor = .lightRed
        
        let emailVerificationParagraphStyle = NSMutableParagraphStyle()
        emailVerificationParagraphStyle.lineHeightMultiple = 1.47
        
        let emailVerificationAttributedText = NSMutableAttributedString(string: "User not found in Permanent database.".localized(), attributes: [NSAttributedString.Key.paragraphStyle: emailVerificationParagraphStyle])
        
        designateStewardEmailVerificationLabel.attributedText = emailVerificationAttributedText
    }
    
    private func customizeInviteUserToPermanentLabel() {
        inviteUserToPermanentLabel.textColor = .darkBlue
        inviteUserToPermanentLabel.font = Text.style35.font
        
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
    
    @objc func doneButtonTapped() {
        if let selectedStewardName = designateStewardNameTextField.text, selectedStewardName.isNotEmpty {
            if let selectedStewardEmail = designateStewardEmailTextField.text, selectedStewardEmail.isNotEmpty {
                if let isValidEmail = viewModel?.isValidEmail(email: selectedStewardEmail), isValidEmail {
                    dismiss(animated: true, completion: { [weak self] in
                        self?.viewModel?.addSelectedSteward(name: selectedStewardName, email: selectedStewardEmail, status: .pending)
                    })
                }
                showAlert(title: "Invalid Email".localized(), message: "Please enter a valid email address.".localized())
            }
            showAlert(title: "Email Required".localized(), message: "Please enter an email address.".localized())
        }
        showAlert(title: "Name Required".localized(), message: "Please enter a name.".localized())
    }

    @objc func cancelButtonTapped() {

        dismiss(animated: true, completion: nil)
    }
    @IBAction func inviteUserToPermanentTapped(_ sender: Any) {
        
    }
    
    private func updateEmailValidationUI(isValid: Bool) {
        if isValid {
            designateStewardEmailStackView.layer.borderColor = UIColor.clear.cgColor
            emailVerificationImageView.isHidden = false
            emailVerificationImageView.image = UIImage(named: "legacyPlanningCheckMark")
            designateStewardEmailVerificationLabel.isHidden = true
            inviteUserToPermanentStackView.isHidden = true
        } else {
            designateStewardEmailStackView.layer.borderColor = UIColor.lightRed.cgColor
            emailVerificationImageView.isHidden = false
            emailVerificationImageView.image = UIImage(named: "legacyPlanningError")
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
            if let isValidEmail = viewModel?.isValidEmail(email: textField.text) {
                updateEmailValidationUI(isValid: isValidEmail)
            }
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == designateStewardEmailTextField {
            if let isValidEmail = viewModel?.isValidEmail(email: textField.text) {
                updateEmailValidationUI(isValid: isValidEmail)
            }
        }
    }
}
