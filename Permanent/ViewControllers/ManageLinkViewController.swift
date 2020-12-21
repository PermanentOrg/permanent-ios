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
    @IBOutlet var expDateInputView: InputSettingsView!
    @IBOutlet var saveButton: RoundedButton!
    @IBOutlet var autoApproveTooltipLabel: UILabel!
    @IBOutlet var maxUsesTooltipLabel: UILabel!
    @IBOutlet var expDateTooltipLabel: UILabel!
    
    var shareViewModel: ShareLinkViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = shareViewModel
        configureUI()
    }
    
    fileprivate func configureUI() {
        view.backgroundColor = .backgroundPrimary
     
        sharePreviewSwitchView.text = .sharePreview
        autoApproveSwitchView.text = .autoApprove
        
        maxUsesInputView.placeholder = .maxNumberUses
        maxUsesInputView.keyboardType = .numberPad
        maxUsesInputView.configureNumericUI()
        
        expDateInputView.placeholder = .expirationDate
        expDateInputView.configureDatePickerUI()
        
        saveButton.configureActionButtonUI(title: .save)
        
        autoApproveTooltipLabel.style(withFont: Text.style4.font, text: .autoApproveTooltip)
        maxUsesTooltipLabel.style(withFont: Text.style4.font, text: .maxUsesTooltip)
        expDateTooltipLabel.style(withFont: Text.style4.font, text: .expDateTooltip)
        
        prefillDataIfNeeded()
    }
    
    fileprivate func prefillDataIfNeeded() {
        sharePreviewSwitchView.toggle(isOn: (viewModel?.shareVO?.previewToggle ?? 0) != 0)
        autoApproveSwitchView.toggle(isOn: (viewModel?.shareVO?.autoApproveToggle ?? 0) != 0)
        
        if let maxUses = viewModel?.shareVO?.maxUses, maxUses != 0 {
            maxUsesInputView.value = String(maxUses)
        }
        
        if let expiresDT = viewModel?.shareVO?.expiresDT {
            expDateInputView.value = expiresDT.dateOnly
        }
    }
    
    // MARK: - Actions
    
    @IBAction func saveAction(_ sender: UIButton) {
        showSpinner()
        
        let manageLinkData = ManageLinkData(
            previewToggle: sharePreviewSwitchView.isToggled ? 1 : 0,
            autoApproveToggle: autoApproveSwitchView.isToggled ? 1 : 0,
            expiresDT: expDateInputView.inputValue.isNotEmpty ? expDateInputView.inputValue : nil,
            maxUses: Int(maxUsesInputView.inputValue) ?? 0
        )
        
        viewModel?.updateLink(
            model: manageLinkData,
            then: { shareVO, error in
                self.hideSpinner()
                
                if shareVO != nil {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: error)
                    }
                }
                
            })
    }
}
