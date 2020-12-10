//  
//  ManageLinkViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import UIKit

class ManageLinkViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet var sharePreviewSwitchView: SwitchSettingsView!
    @IBOutlet var autoApproveSwitchView: SwitchSettingsView!
    @IBOutlet var maxUsesInputView: InputSettingsView!
    @IBOutlet var expDatePickerView: InputSettingsView!
    
    @IBOutlet var cancelButton: RoundedButton!
    @IBOutlet var saveButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ShareLinkViewModel()
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
     
        sharePreviewSwitchView.text = .sharePreview
        autoApproveSwitchView.text = .autoApprove
        maxUsesInputView.placeholder = .maxNumberUses
        expDatePickerView.placeholder = .expirationDate
        expDatePickerView.configureDatePickerUI()
        
        cancelButton.configureActionButtonUI(title: .cancel)
        saveButton.configureActionButtonUI(title: .save)
    }
    
    // MARK: - Actions
    
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
    }
}
