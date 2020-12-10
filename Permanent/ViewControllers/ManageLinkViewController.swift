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
     
        sharePreviewSwitchView.text = "Share preview"
        autoApproveSwitchView.text = "Auto approve"
        
        maxUsesInputView.placeholder = "Max uses"
        expDatePickerView.placeholder = "Expiration date (opt)"
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
    
    fileprivate func displayDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        
        let pickerSize : CGSize = datePicker.sizeThatFits(.zero)
        datePicker.frame = CGRect(x: 0, y: 250, width: pickerSize.width, height: 460)
            
        view.addSubview(datePicker)
    }
    
}
