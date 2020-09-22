//
//  VerificationCodeController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class VerificationCodeController: BaseViewController<VerificationCodeViewModel> {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var copyrightLabel: UILabel!
    @IBOutlet private var codeField: CustomTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .darkBlue
        
        titleLabel.text = "Enter verification code"
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        copyrightLabel.text = "© The Permanent Legacy Foundation 2020"
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        codeField.placeholder = "Enter the 4-digit code"
        codeField.delegate = self
        codeField.smartInsertDeleteType = .no
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: UIButton) {}
}

extension VerificationCodeController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        return newLength <= 4 // TODO: Make a property in TextField for this value
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
