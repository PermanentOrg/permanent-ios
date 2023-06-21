//
//  UpdateNecessaryViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.03.2022.
//

import UIKit
import Firebase

class UpdateNecessaryViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var updateTextLabel: UILabel!
    @IBOutlet weak var updateButton: RoundedButton!
    
    @IBOutlet weak var imageViewCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var updateTextTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var updateButtonConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateTextLabel.attributedText = TextFontStyle.style17.setTextWithLineSpacing(text: Constants.onboardingTextNormal[0])
        updateTextLabel.font = TextFontStyle.style17.font
        updateTextLabel.textAlignment = .center
        updateTextLabel.textColor = .white
        updateTextLabel.text = "Update Permanent Archive? \n\nYou must update to the latest version of this app in order to maintain access to your Permanent Archives on this device.".localized()
        
        updateButton.setTitle("Update".localized(), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imageViewCenterConstraint.constant -= 90
        updateTextTopConstraint.constant = 20
        updateButtonConstraint.constant = 20
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.updateButton.alpha = 1.0
                self.updateTextLabel.alpha = 1.0
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    @IBAction func updateButtonAction(_ sender: Any) {
        UIView.setAnimationsEnabled(false)
        if let url = URL(string: "https://itunes.apple.com/us/app/permanent-archive/id1571883070") {
            UIApplication.shared.open(url)
        }
    }
}
