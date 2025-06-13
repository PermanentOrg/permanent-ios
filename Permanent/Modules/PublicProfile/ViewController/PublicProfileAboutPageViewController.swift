//
//  PublicProfileAboutPageViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.11.2021.
//

import UIKit

class PublicProfileAboutPageViewController: BaseViewController<PublicProfilePageViewModel> {
    @IBOutlet weak var shortAboutDescriptionTitleLabel: UILabel!
    @IBOutlet weak var shortAboutDescriptionTextField: UITextField!
    @IBOutlet weak var longAboutDescriptionTextView: UITextView!
    @IBOutlet weak var longAboutDescriptionTitleLabel: UILabel!

    @IBOutlet weak var shortDescriptionEmptyLabel: UILabel!
    @IBOutlet weak var longDescriptionEmptyLabel: UILabel!
    
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var archiveNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        initUI()
        
        shortAboutDescriptionTextField.delegate = self
        longAboutDescriptionTextView.delegate = self
        
        addDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    func setupNavigationBar() {
        styleNavBar()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction(_:)))
    }
    
    func initUI() {
        title = viewModel?.archiveType.aboutPublicPageTitle
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        shortAboutDescriptionTextField.layer.borderColor = UIColor.lightGray.cgColor
        shortAboutDescriptionTextField.layer.borderWidth = 0.5
        shortAboutDescriptionTextField.layer.cornerRadius = 3
        shortAboutDescriptionTextField.textColor = .middleGray
        shortAboutDescriptionTextField.font = TextFontStyle.style7.font
        
        longAboutDescriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        longAboutDescriptionTextView.layer.borderWidth = 0.5
        longAboutDescriptionTextView.layer.cornerRadius = 3
        longAboutDescriptionTextView.textColor = .middleGray
        longAboutDescriptionTextView.font = TextFontStyle.style7.font
        
        archiveNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        archiveNameTextField.layer.borderWidth = 0.5
        archiveNameTextField.layer.cornerRadius = 3
        archiveNameTextField.textColor = .middleGray
        archiveNameTextField.font = TextFontStyle.style7.font
        
        shortDescriptionEmptyLabel.textColor = .lightGray
        shortDescriptionEmptyLabel.font = TextFontStyle.style8.font
        shortDescriptionEmptyLabel.textAlignment = .left
        
        longDescriptionEmptyLabel.textColor = .lightGray
        longDescriptionEmptyLabel.font = TextFontStyle.style8.font
        longDescriptionEmptyLabel.textAlignment = .left
        
        archiveNameLabel.textColor = .middleGray
        archiveNameLabel.font = TextFontStyle.style12.font
        
        shortAboutDescriptionTitleLabel.textColor = .middleGray
        shortAboutDescriptionTitleLabel.font = TextFontStyle.style12.font
        
        longAboutDescriptionTitleLabel.textColor = .middleGray
        longAboutDescriptionTitleLabel.font = TextFontStyle.style12.font
        
        archiveNameLabel.text = "Archive Name"
        shortAboutDescriptionTitleLabel.text = "\(viewModel?.archiveType.shortDescriptionTitle ?? "") (<COUNT>/200)".localized().replacingOccurrences(of: "<COUNT>", with: "\(viewModel?.blurbProfileItem?.shortDescription?.count ?? 0)")
        shortDescriptionEmptyLabel.text = viewModel?.archiveType.shortDescriptionHint
        
        if let archiveName = viewModel?.basicProfileItem?.archiveName {
            archiveNameTextField.text = archiveName
        }
        
        if let shortDescription = viewModel?.blurbProfileItem?.shortDescription {
            shortAboutDescriptionTextField.text = shortDescription
            shortDescriptionEmptyLabel.isHidden = true
        } else {
            shortDescriptionEmptyLabel.isHidden = false
        }
        
        if let longDescription = viewModel?.descriptionProfileItem?.longDescription {
            longAboutDescriptionTextView.text = longDescription
            longDescriptionEmptyLabel.isHidden = true
        } else {
            longDescriptionEmptyLabel.isHidden = false
        }
        
        longAboutDescriptionTitleLabel.text = viewModel?.archiveType.longDescriptionTitle
        longDescriptionEmptyLabel.text = viewModel?.archiveType.longDescriptionHint
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    @objc func doneButtonAction(_ sender: Any) {
        var publicProfileUpdateIsSuccessfully: (Bool, Bool, Bool) = (true, true, true)
        
        let group = DispatchGroup()
        
        showSpinner()
        
        if let archiveNameTextField = archiveNameTextField.text {
            if archiveNameTextField != viewModel?.archiveNameProfileItem?.archiveName && archiveNameTextField.count <= 30 {
                if !archiveNameTextField.isEmpty {
                        group.enter()
                        viewModel?.renameArchiveNameProfileItem(profileItemId: viewModel?.archiveNameProfileItem?.profileItemId ,newValue: archiveNameTextField, { result, error, itemId in
                            if result {
                                self.viewModel?.archiveNameProfileItem?.profileItemId = itemId
                                
                                // Check if we're editing the currently selected archive
                                if let currentArchive = AuthenticationManager.shared.session?.selectedArchive,
                                   let localArchiveData = self.viewModel?.archiveData,
                                   currentArchive.archiveID == localArchiveData.archiveID {
                
                                    // Skip session sync and notification posting to prevent unwanted archive switching
                                    // The main profile page (PublicProfilePageViewController) handles this correctly
                                }
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                                publicProfileUpdateIsSuccessfully.2 = false
                            }
                            group.leave()
                        })
                } else {
                    self.archiveNameTextField.text = viewModel?.archiveData.fullName
                }
            }
        }
             
        if let shortTextField = shortAboutDescriptionTextField.text {
            if shortTextField != viewModel?.blurbProfileItem?.shortDescription {
                if shortTextField.isEmpty {
                    if let shortProfileItemId = viewModel?.blurbProfileItem?.profileItemId {
                        group.enter()
                        
                        viewModel?.modifyBlurbProfileItem(profileItemId: shortProfileItemId, newValue: "", operationType: .delete, { result, error, itemId in
                            if result {
                                self.viewModel?.blurbProfileItem?.profileItemId = nil
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                                publicProfileUpdateIsSuccessfully.0 = false
                            }
                            group.leave()
                        })
                    }
                } else {
                    group.enter()
                    
                    viewModel?.modifyBlurbProfileItem(profileItemId: viewModel?.blurbProfileItem?.profileItemId, newValue: shortTextField, operationType: .update, { result, error, itemId  in
                        if result {
                            self.viewModel?.blurbProfileItem?.profileItemId = itemId
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
            if longTextView != viewModel?.descriptionProfileItem?.longDescription {
                if longTextView.isEmpty {
                    if let longProfileItemId = viewModel?.descriptionProfileItem?.profileItemId {
                        group.enter()
                        
                        viewModel?.modifyDescriptionProfileItem(profileItemId: longProfileItemId, newValue: "", operationType: .delete, { result, error, itemId in
                            if result {
                                self.viewModel?.descriptionProfileItem?.profileItemId = nil
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                                publicProfileUpdateIsSuccessfully.1 = false
                            }
                            group.leave()
                        })
                    }
                } else {
                    group.enter()
                    
                    viewModel?.modifyDescriptionProfileItem(profileItemId: viewModel?.descriptionProfileItem?.profileItemId, newValue: longTextView, operationType: .update, { result, error, itemId  in
                        if result {
                            self.viewModel?.descriptionProfileItem?.profileItemId = itemId
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
            if publicProfileUpdateIsSuccessfully == (true, true, true) {
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
        
        shortAboutDescriptionTitleLabel.text = "\(viewModel?.archiveType.shortDescriptionTitle ?? "") (<COUNT>/200)".localized().replacingOccurrences(of: "<COUNT>", with: "\(textCount)")
        
        if textCount < 200 {
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
