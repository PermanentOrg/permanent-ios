//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit
import AVKit

class FilePreviewViewController: BaseViewController<FilePreviewViewModel> {
    let fileHelper = FileHelper()
    
    var file: FileViewModel!
    
    var playerItem: AVPlayerItem?
    var videoPlayer: AVPlayerViewController?
    
    let documentInteractionController = UIDocumentInteractionController()

    deinit {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        viewModel = FilePreviewViewModel(file: file)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showSpinner()
        
        viewModel?.getRecord(file: file, then: { record in
            guard let fileVO = self.viewModel?.fileVO(),
                  let fileName = self.viewModel?.fileName()
            else {
                return
            }
                  
            if let localURL = self.fileHelper.url(forFileNamed: fileName),
               let contentType = fileVO.contentType {
                switch self.file.type {
                case FileType.image:
                    self.loadImage(withURL: localURL, contentType: contentType)
                case FileType.video:
                    self.loadVideo(withURL: localURL, contentType: contentType)
                default:
                    self.loadMisc(withURL: localURL)
                }
            } else if let downloadURLString = fileVO.downloadURL,
                      let contentType = fileVO.contentType,
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
        let shareButtonImage = UIBarButtonItem.SystemItem.action
        let shareButton = UIBarButtonItem(barButtonSystemItem: shareButtonImage, target: self, action: #selector(shareButtonAction(_:)))
        
        let infoButton = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(infoButtonAction(_:)))
        navigationItem.rightBarButtonItems = [shareButton, infoButton]

        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        
        navigationItem.title = file.name
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
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
    
    // MARK: - Load methods
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
        let asset = AVURLAsset(url: url, options: ["AVURLAssetOutOfBandMIMETypeKey": contentType])
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        
        let player = AVPlayer(playerItem: playerItem)
        videoPlayer = AVPlayerViewController()
        videoPlayer!.player = player
        player.play()
        
        addChild(videoPlayer!)
        videoPlayer!.view.frame = view.bounds
        view.insertSubview(videoPlayer!.view, at: 0)
        videoPlayer!.didMove(toParent: self)
        
        hideSpinner()
    }
    
    func loadMisc(withURL url: URL) {
        let webView = setupWebView()
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Actions
    @objc private func shareButtonAction(_ sender: Any) {
        if let fileName = self.viewModel?.fileName(),
            let localURL = fileHelper.url(forFileNamed: fileName) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            }))
            
            present(preparingAlert, animated: true) {
                if let record = self.viewModel?.recordVO {
                    self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { url, _ in
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
    
    @objc private func infoButtonAction(_ sender: Any) {
        playerItem?.removeObserver(self, forKeyPath: "status")
        videoPlayer?.player?.pause()
        
        let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap , from: .main) as! FileDetailsViewController
        fileDetailsVC.file = file
        
        navigationController?.setViewControllers([fileDetailsVC], animated: false)
    }

    @objc private func closeButtonAction(_ sender: Any) {
        playerItem?.removeObserver(self, forKeyPath: "status")
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status", let item = object as? AVPlayerItem else {
            return
        }
        
        hideSpinner()
        
        if item.status == .failed {
            showAlert(title: .error, message: "Sorry, can't play this video format.".localized())
        }
    }
    
    //MARK: -
    private func share(url: URL) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        documentInteractionController.dismissMenu(animated: true)
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
    }
    
    private func htmlBody(withContent content: String) -> String {
        return "<html><body style=\"width:\(UIScreen.main.scale * view.frame.width);height:\(UIScreen.main.scale * view.frame.height);background-color:#000000;margin:0;padding:0;\">\(content)</body></html>"
    }
}

// MARK: - WKNavigationDelegate
extension FilePreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideSpinner()
    }
}
