//
//  PublicProfileAboutPageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.11.2021.
//

import UIKit
import AVFoundation

class PublicProfileAboutPageViewController: BaseViewController<PublicProfilePageViewModel> {
    
    var shortDescription: String?
    var longDescription: String?
    var shortAboutProfileItemId: Int?
    var longAboutProfileItemId: Int?
    
    var screenTitle: String = "About This Archive".localized()
    var archiveType: ArchiveType!
    
    @IBOutlet weak var shortAboutDescriptionTitleLabel: UILabel!
    @IBOutlet weak var shortAboutDescriptionTextField: UITextField!
    @IBOutlet weak var longAboutDescriptionTextView: UITextView!
    @IBOutlet weak var longAboutDescriptionTitleLabel: UILabel!

    @IBOutlet weak var shortDescriptionEmptyLabel: UILabel!
    @IBOutlet weak var longDescriptionEmptyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = screenTitle.localized()
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        setupNavigationBar()
        
        initUI()
        
        shortAboutDescriptionTextField.delegate = self
        longAboutDescriptionTextView.delegate = self
        
        self.addDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    func initUI() {
        
        shortAboutDescriptionTextField.layer.borderColor = UIColor.lightGray.cgColor
        shortAboutDescriptionTextField.layer.borderWidth = 0.5
        shortAboutDescriptionTextField.layer.cornerRadius = 3
        shortAboutDescriptionTextField.textColor = .middleGray
        shortAboutDescriptionTextField.font = Text.style7.font
        
        longAboutDescriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        longAboutDescriptionTextView.layer.borderWidth = 0.5
        longAboutDescriptionTextView.layer.cornerRadius = 3
        longAboutDescriptionTextView.textColor = .middleGray
        longAboutDescriptionTextView.font = Text.style7.font
        
        shortDescriptionEmptyLabel.textColor = .lightGray
        shortDescriptionEmptyLabel.font = Text.style8.font
        shortDescriptionEmptyLabel.textAlignment = .left
        
        longDescriptionEmptyLabel.textColor = .lightGray
        longDescriptionEmptyLabel.font = Text.style8.font
        longDescriptionEmptyLabel.textAlignment = .left
        
        shortAboutDescriptionTitleLabel.textColor = .middleGray
        shortAboutDescriptionTitleLabel.font = Text.style12.font
        
        longAboutDescriptionTitleLabel.textColor = .middleGray
        longAboutDescriptionTitleLabel.font = Text.style12.font
        
        shortAboutDescriptionTitleLabel.text = "What is this Archive for? (<COUNT>/280)".localized().replacingOccurrences(of: "<COUNT>", with: "\(shortDescription?.count ?? 0)")
        shortDescriptionEmptyLabel.text = "Add a short description about the purpose of this Archive".localized()
        
        if let shortDescription = shortDescription {
            shortAboutDescriptionTextField.text = shortDescription
            shortDescriptionEmptyLabel.isHidden = true
        } else {
            shortDescriptionEmptyLabel.isHidden = false
        }
        
        if let longDescription = longDescription {
            longAboutDescriptionTextView.text = longDescription
            longDescriptionEmptyLabel.isHidden = true
        } else {
            longDescriptionEmptyLabel.isHidden = false
        }
        
        switch archiveType {
        case .person:
            longAboutDescriptionTitleLabel.text = "Tell us about this Person".localized()
            longDescriptionEmptyLabel.text = "Tell the story of the Person this Archive is for".localized()
        case .family:
            
            longAboutDescriptionTitleLabel.text = "Tell us about this Family".localized()
            longDescriptionEmptyLabel.text = "Tell the story of the Family this Archive is for".localized()
        case .organization:
            
            longAboutDescriptionTitleLabel.text = "Tell us about this Organization".localized()
            longDescriptionEmptyLabel.text = "Tell the story of the Organization this Archive is for".localized()
        case .none: break
        }
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonAction(_ sender: Any) {
        var publicProfileUpdateIsSuccessfully: (Bool,Bool) = (true,true)
        
        let group = DispatchGroup()
        
        showSpinner()
             
        if let shortTextField = shortAboutDescriptionTextField.text {
            if shortTextField != shortDescription {
                
                if shortTextField.isEmpty {
                    if let shortProfileItemId = shortAboutProfileItemId {
                        group.enter()
                        viewModel?.modifyPublicProfileItem(.shortDescription, "", .delete, shortProfileItemId, { result, error, itemId in
                            if result {
                                self.shortAboutProfileItemId = nil
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                                publicProfileUpdateIsSuccessfully.0 = false
                            }
                        group.leave()
                        })
                    }
            
                } else {
                    group.enter()
                    viewModel?.modifyPublicProfileItem(.shortDescription, shortTextField, .update, shortAboutProfileItemId, { result, error, itemId  in
                        if result {
                            self.shortAboutProfileItemId = itemId
                        } else {
                            self.showAlert(title: .error, message: .errorMessage)
                            publicProfileUpdateIsSuccessfully.0 = false
                        }
                        group.leave()
                    })
                }
            }
        }
        
        if let longTextView = longAboutDescriptionTextView.text {
            if longTextView != longDescription {
                
                if longTextView.isEmpty {
                    if let longProfileItemId = longAboutProfileItemId {
                        group.enter()
                        viewModel?.modifyPublicProfileItem(.longDescription, "", .delete, longProfileItemId, { result, error, itemId in
                            if result {
                                self.longAboutProfileItemId = nil
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                                publicProfileUpdateIsSuccessfully.1 = false
                            }
                            group.leave()
                        })
                    }
                } else {
                    group.enter()
                    viewModel?.modifyPublicProfileItem(.longDescription, longTextView, .update, longAboutProfileItemId, { result, error, itemId  in
                        if result {
                            self.longAboutProfileItemId = itemId
                        } else {
                            self.showAlert(title: .error, message: .errorMessage)
                            publicProfileUpdateIsSuccessfully.1 = false
                        }
                        group.leave()
                    })
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.hideSpinner()
            if publicProfileUpdateIsSuccessfully == (true, true) {
                self.dismiss(animated: true)
            }
        }
    }
}

extension PublicProfileAboutPageViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {

            longDescriptionEmptyLabel.isHidden = true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            longDescriptionEmptyLabel.isHidden = false
        }
    }
}

extension PublicProfileAboutPageViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        shortDescriptionEmptyLabel.isHidden = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let textFieldText = textField.text else { return false }
        
        let textCount = textFieldText.count + string.count - range.length
        
        shortAboutDescriptionTitleLabel.text = "What is this Archive for? (<COUNT>/280)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
        
        if textCount < 280 {
            return true
        }
        
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let textFieldText = textField.text else { return }
        
        if textFieldText.isEmpty {
            shortDescriptionEmptyLabel.isHidden = false
        }
    }
}
