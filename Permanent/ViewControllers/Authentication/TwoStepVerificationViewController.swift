//
//  TwoStepVerificationViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit

class TwoStepVerificationViewController: UIViewController {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var extraInfoLabel: UILabel!
    @IBOutlet private var confirmButton: RoundedButton!
    @IBOutlet private var skipButton: UIButton!
    @IBOutlet private var phoneField: CustomTextField!
    @IBOutlet private var copyrightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Move this to base delegate
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        
        titleLabel.text = Translations.twoStepTitle
        titleLabel.textColor = .white
        titleLabel.font = Text.style.font
        
        subtitleLabel.text = Translations.twoStepSubtitle
        subtitleLabel.textColor = .white
        subtitleLabel.font = Text.style2.font
        
        extraInfoLabel.text = Translations.addLater
        extraInfoLabel.textColor = .lightGray
        extraInfoLabel.font = Text.style6.font
        
        confirmButton.setTitle(Translations.submit, for: [])
    
        skipButton.setTitle(Translations.skip, for: [])
        skipButton.setFont(Text.style9.font)
        skipButton.setTitleColor(.white, for: [])
        
        copyrightLabel.text = Translations.copyrightText
        copyrightLabel.textColor = .white
        copyrightLabel.font = Text.style12.font
        
        phoneField.placeholder = "( ___ ) ___ - ____"
        phoneField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func confirmAction(_ sender: RoundedButton) {}
    
    @IBAction func skipAction(_ sender: UIButton) {}
}

extension TwoStepVerificationViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? TextField)?.toggleBorder(active: false)
    }
}
