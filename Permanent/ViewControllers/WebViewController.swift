//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit

class WebViewController: BaseViewController<WebViewModel> {
    let webView = WKWebView()
    let fileHelper = FileHelper()
    
    var file: FileViewModel!
    var operation: APIOperation?
    
    var recordVO: RecordVO?
    
    let documentInteractionController = UIDocumentInteractionController()

    override func loadView() {
        view = webView
        webView.navigationDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        viewModel = WebViewModel(csrf: file.csrf ?? "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showSpinner()
        
        viewModel?.getRecord(file: file, then: { record in
            self.recordVO = record
            
            if let localURL = self.fileHelper.url(forFileNamed: record?.recordVO?.uploadFileName ?? "") {
                self.webView.loadFileURL(localURL, allowingReadAccessTo: localURL)
            } else if let downloadURLString = record?.recordVO?.fileVOS?.first?.downloadURL,
                      let contentType = record?.recordVO?.fileVOS?.first?.contentType,
                      let downloadURL = URL(string: downloadURLString) {
                let request = URLRequest(url: downloadURL)
                
                let videoTag = "<video style=\"max-width:100%;max-height:100%;margin:50% auto 0 auto;padding:0;\" controls autoplay> <source src=\"\(downloadURLString)\" type=\"\(contentType)\">Your browser does not support the video tag.</video>"
                
                let htmlBody = "<html><body style=\"width:100%;height:100%;background-color:#000000;margin:0;padding:0;\">\(videoTag)</body></html>"
                self.webView.loadHTMLString(htmlBody, baseURL: nil)
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
    
    func share(url: URL) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        documentInteractionController.dismissMenu(animated: true)
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
    }

    @objc private func shareButtonAction(_ sender: Any) {
        if let localURL = self.fileHelper.url(forFileNamed: recordVO?.recordVO?.uploadFileName ?? "") {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..", message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                self.viewModel?.cancelDownload()
            }))
            
            present(preparingAlert, animated: true) {
                if let record = self.recordVO {
                    self.viewModel?.download(record, onFileDownloaded: { (url, error) in
                        if let url = url {
                            self.dismiss(animated: true) {
                                self.share(url: url)
                            }
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }

    @objc private func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner()
    }
    
}
