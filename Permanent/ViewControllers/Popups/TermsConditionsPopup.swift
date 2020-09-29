//
//  TermsConditionsPopup.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit
import WebKit

class TermsConditionsPopup: UIViewController {
    @IBOutlet private var contentView: UIView!
    @IBOutlet var navBarView: NavigationBarView!
    @IBOutlet private var webView: WKWebView!
    @IBOutlet var declineButton: RoundedButton!
    @IBOutlet var acceptButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }
    
    fileprivate func initUI() {
        view.backgroundColor = .primary
        contentView.backgroundColor = .backgroundPrimary
        webView.backgroundColor = .backgroundPrimary
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        view.addGestureRecognizer(tap)
        
        let link = URL(string:"https://www.permanent.org/privacy-policy/")!
        let request = URLRequest(url: link)
        webView.load(request)
        
        
        declineButton.backgroundColor = .lightGray
        declineButton.setTitle(Translations.decline, for: [])
        
        declineButton.backgroundColor = .secondary
        acceptButton.setTitle(Translations.accept, for: [])
        
        navBarView.title = Translations.termsConditions
        if #available(iOS 13.0, *) {
            navBarView.icon = UIImage(systemName: "xmark")
        }
    }
    
    @objc
    func close() {
        dismiss(animated: true, completion: nil)
    }
}
