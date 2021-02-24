//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit

class WebViewController: BaseViewController<WebViewModel> {
    var webView = WKWebView()
    var file : FileViewModel!
    var csrf : String!
    var operation : APIOperation?
    override func loadView() {
        self.view = webView
        webView.navigationDelegate = self
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = WebViewModel()
        viewModel?.downloadFile(csrf: csrf, file: file, then: { (result,request) in
            if result {
                self.webView.load(request!)
                
            } else {
                showErrorAlert(message: .errorMessage)
            }
        })
    }
}

extension WebViewController: WKNavigationDelegate {
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//
//    }
    private func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError)
    {
       if(error.code == NSURLErrorNotConnectedToInternet)
       {
           print("error")
       }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}
