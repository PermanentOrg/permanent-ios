//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit

class FilePreviewViewController: BaseViewController<FilePreviewViewModel> {
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
        
        viewModel = FilePreviewViewModel(csrf: file.csrf ?? "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showSpinner()
        
        viewModel?.getRecord(file: file, then: { record in
            self.recordVO = record
            
            if let localURL = self.fileHelper.url(forFileNamed: record?.recordVO?.uploadFileName ?? ""),
               let contentType = record?.recordVO?.fileVOS?.first?.contentType
            {
                switch self.file.type {
                case FileType.image:
                    let imageTag = "<body style=\"width:\(self.view.frame.width * UIScreen.main.scale);height:\(self.view.frame.height * UIScreen.main.scale);background-color:#000000;\"><img src=\"\(localURL)\" style=\"max-width:\(self.view.frame.width * UIScreen.main.scale);max-height:\(self.view.frame.height * UIScreen.main.scale);margin:0;padding:0;position:absolute;top:50%;left:50%;transform:translate(-50%, -50%);\"/></body>"
                    let htmlBody = "<html><body style=\"width:100%;height:100%;background-color:#000000;margin:0;padding:0;\">\(imageTag)</body></html>"
                    self.webView.loadHTMLString(htmlBody, baseURL: localURL)
                case FileType.video:
                    let videoTag = "<video style=\"max-width:100%;max-height:100%;margin:50% auto 0 auto;padding:0;\" controls autoplay> <source src=\"\(localURL)\" type=\"\(contentType)\">Your browser does not support the video tag.</video>"
                    let htmlBody = "<html><body style=\"width:100%;height:100%;background-color:#000000;margin:0;padding:0;\">\(videoTag)</body></html>"
                    self.webView.loadHTMLString(htmlBody, baseURL: localURL)
                default:
                    self.webView.loadFileURL(localURL, allowingReadAccessTo: localURL)
                }
            
            } else if let downloadURLString = record?.recordVO?.fileVOS?.first?.downloadURL,
                      let contentType = record?.recordVO?.fileVOS?.first?.contentType,
                      let downloadURL = URL(string: downloadURLString)
            {
                switch self.file.type {
                case FileType.image:
                    let imageTag = "<body style=\"width:\(self.view.frame.width * UIScreen.main.scale);height:\(self.view.frame.height * UIScreen.main.scale);background-color:#000000;\"><img src=\"\(downloadURLString)\" style=\"max-width:\(self.view.frame.width * UIScreen.main.scale);max-height:\(self.view.frame.height * UIScreen.main.scale);margin:0;padding:0;position:absolute;top:50%;left:50%;transform:translate(-50%, -50%);\"/></body>"
                    let htmlBody = "<html><body style=\"width:100%;height:100%;background-color:#000000;margin:0;padding:0;\">\(imageTag)</body></html>"
                    self.webView.loadHTMLString(htmlBody, baseURL: nil)
                case FileType.video:
                    let videoTag = "<video style=\"max-width:100%;max-height:100%;margin:50% auto 0 auto;padding:0;\" controls autoplay> <source src=\"\(downloadURLString)\" type=\"\(contentType)\">Your browser does not support the video tag.</video>"
                    let htmlBody = "<html><body style=\"width:100%;height:100%;background-color:#000000;margin:0;padding:0;\">\(videoTag)</body></html>"
                    self.webView.loadHTMLString(htmlBody, baseURL: nil)
                default:
                    let request = URLRequest(url: downloadURL)
                    self.webView.load(request)
                }
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
        
        navigationItem.title = file.name
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
        if let localURL = fileHelper.url(forFileNamed: recordVO?.recordVO?.uploadFileName ?? "") {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..", message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            }))
            
            present(preparingAlert, animated: true) {
                if let record = self.recordVO {
                    self.viewModel?.download(record, onFileDownloaded: { url, _ in
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

extension FilePreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // hide spinner for audio files
        hideSpinner()
    }
}
