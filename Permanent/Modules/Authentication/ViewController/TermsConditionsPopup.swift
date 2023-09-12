//
//  TermsConditionsPopup.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//

import UIKit
import WebKit

protocol TermsConditionsPopupDelegate: AnyObject {
    func didAccept()
}

class TermsConditionsPopup: UIViewController {
    @IBOutlet private var contentView: UIView!
    @IBOutlet var navBarView: NavigationBarView!
    @IBOutlet var declineButton: RoundedButton!
    @IBOutlet var acceptButton: RoundedButton!
    
    weak var delegate: TermsConditionsPopupDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        declineButton.backgroundColor = .lightGray
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        contentView.backgroundColor = .backgroundPrimary

        declineButton.setTitle(.decline, for: [])
        acceptButton.setTitle(.accept, for: [])
        
        navBarView.title = .termsConditions
        navBarView.icon = UIImage(named: "close")
        navBarView.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func acceptAction(_ sender: RoundedButton) {
        delegate?.didAccept()
        close()
    }
    
    @IBAction func declineAction(_ sender: RoundedButton) {
        close()
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension TermsConditionsPopup: NavigationBarViewDelegate {
    func didTapLeftButton() {
        close()
    }
}
