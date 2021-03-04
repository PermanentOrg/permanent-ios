//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit

class FilePreviewViewController: BaseViewController<FilePreviewViewModel> {
    let fileHelper = FileHelper()
    
    var file: FileViewModel!
    var operation: APIOperation?
    
    var recordVO: RecordVO?
    
    let documentInteractionController = UIDocumentInteractionController()

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
               let contentType = record?.recordVO?.fileVOS?.first?.contentType {
                switch self.file.type {
                case FileType.image:
                    self.loadImage(withURL: localURL, contentType: contentType)
                case FileType.video:
                    self.loadVideo(withURL: localURL, contentType: contentType)
                default:
                    self.loadMisc(withURL: localURL)
                }
            } else if let downloadURLString = record?.recordVO?.fileVOS?.first?.downloadURL,
                      let contentType = record?.recordVO?.fileVOS?.first?.contentType,
                      let downloadURL = URL(string: downloadURLString) {
                switch self.file.type {
                case FileType.image:
                    self.loadImage(withURL: downloadURL, contentType: contentType)
                case FileType.video:
                    self.loadVideo(withURL: downloadURL, contentType: contentType)
                default:
                    self.loadMisc(withURL: downloadURL)
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
    
    func setupWebView() -> WKWebView {
        let webView = WKWebView(frame: view.bounds)
        webView.backgroundColor = .black
        webView.navigationDelegate = self
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(webView, at: 0)
        
        return webView
    }
    
    func htmlBody(withContent content: String) -> String {
        return "<html><body style=\"width:\(UIScreen.main.scale * view.frame.width);height:\(UIScreen.main.scale * view.frame.height);background-color:#000000;margin:0;padding:0;\">\(content)</body></html>"
    }
    
    func loadImage(withURL url: URL, contentType: String, size: CGSize = .zero) {
        let imagePreviewVC = ImagePreviewViewController()
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        // Insert view under the spinner
        view.insertSubview(imagePreviewVC.view, at: 0)
        imagePreviewVC.didMove(toParent: self)
        
        viewModel?.fileData(withURL: url, onCompletion: { (data, error) in
            if let data = data {
                imagePreviewVC.image = UIImage(data: data)
                self.hideSpinner()
            } else {
                self.showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    func loadVideo(withURL url: URL, contentType: String) {
        let webView = setupWebView()
        
        let videoTag = "<video style=\"display:block;max-width:100%;max-height:100%;margin:50% auto;padding:0;\" controls autoplay> <source src=\"\(url)\" type=\"\(contentType)\">Your browser does not support the video tag.</video>"
        webView.loadHTMLString(htmlBody(withContent: videoTag), baseURL: url)
    }
    
    func loadMisc(withURL url: URL) {
        let webView = setupWebView()
        
        let request = URLRequest(url: url)
        webView.load(request)
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
        hideSpinner()
    }
}
