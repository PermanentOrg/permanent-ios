//
//  TermsConditionsPopup.swift
//  Permanent
//
//  Created by Adrian Creteanu on 29/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit
import WebKit

protocol TermsConditionsPopupDelegate: class {
    func didAccept()
}

class TermsConditionsPopup: UIViewController {
    @IBOutlet private var contentView: UIView!
    @IBOutlet var navBarView: NavigationBarView!
    @IBOutlet private var webView: WKWebView!
    @IBOutlet var declineButton: RoundedButton!
    @IBOutlet var acceptButton: RoundedButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
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
        webView.backgroundColor = .backgroundPrimary
        activityIndicator.color = .secondary
        
        let link = URL(string: Constants.URL.termsConditionsURL)
        let request = URLRequest(url: link!)
        webView.load(request)
        webView.navigationDelegate = self
        
        declineButton.setTitle(Translations.decline, for: [])
        acceptButton.setTitle(Translations.accept, for: [])
        
        navBarView.title = Translations.termsConditions
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

extension TermsConditionsPopup: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
