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
    var file: FileViewModel!
    var operation: APIOperation?

    override func loadView() {
        view = webView
        webView.navigationDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        viewModel = WebViewModel()
        viewModel?.downloadFile(csrf: file.csrf ?? "", file: file, then: { result, request in
            if result {
                self.webView.load(request!)

            } else {
                self.showErrorAlert(message: .errorMessage)
            }
        })
    }

    func initUI() {
        styleNavBar()
        let rightButtonImage = UIBarButtonItem.SystemItem.action
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: rightButtonImage, target: self, action: #selector(shareButtonAction(_:)))

        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
    }

    @objc private func shareButtonAction(_ sender: Any) {
        print("share tapped")
    }

    @objc private func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension WebViewController: WKNavigationDelegate {}
