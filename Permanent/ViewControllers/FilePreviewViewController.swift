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
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? [.allButUpsideDown] : [.all]
    }
    
    let fileHelper = FileHelper()
    
    var file: FileViewModel!
    
    var playerItem: AVPlayerItem?
    var videoPlayer: AVPlayerViewController?
    var playerItemContext = 0
    
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        showSpinner()
        if viewModel == nil {
            viewModel = FilePreviewViewModel(file: file)
            
            viewModel?.getRecord(file: file, then: { record in
                self.loadRecord()
            })
        } else {
            loadRecord()
        }
    }

    func initUI() {
        styleNavBar()
        let shareButtonImage = UIBarButtonItem.SystemItem.action
        let shareButton = UIBarButtonItem(barButtonSystemItem: shareButtonImage, target: self, action: #selector(shareButtonAction(_:)))
        
        let infoButton = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(infoButtonAction(_:)))
        navigationItem.rightBarButtonItems = [shareButton, infoButton]
        
        title = file.name
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.barTintColor = .black
    }
    
    func setupWebView() -> WKWebView {
        let webView = WKWebView(frame: view.bounds)
        webView.backgroundColor = .black
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.frame = view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(webView, at: 0)
        
        return webView
    }
    
    // MARK: - Load methods
    func loadRecord() {
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
    }
    
    func loadImage(withURL url: URL, contentType: String, size: CGSize = .zero) {
        let imagePreviewVC = ImagePreviewViewController()
        imagePreviewVC.delegate = self
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
        let playerItem = AVPlayerItem(asset: asset)
//        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &playerItemContext)
        
        let player = AVPlayer(playerItem: playerItem)
        videoPlayer = AVPlayerViewController()
        videoPlayer!.player = player
//        player.play()
        
        self.playerItem = playerItem
        
        addChild(videoPlayer!)
        videoPlayer!.view.frame = view.bounds.insetBy(dx: 0, dy: 60)
        view.insertSubview(videoPlayer!.view, at: 0)
        videoPlayer!.didMove(toParent: self)
        
        hideSpinner()
    }
    
    func loadMisc(withURL url: URL) {
        let webView = setupWebView()
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func removeVideoPlayer() {
//        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)
        videoPlayer?.player?.replaceCurrentItem(with: nil)
        
        videoPlayer?.willMove(toParent: nil)
        videoPlayer?.view.removeFromSuperview()
        videoPlayer?.removeFromParent()
    }
    
    // MARK: - Actions
    @objc func shareButtonAction(_ sender: Any) {
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
    
    @objc func infoButtonAction(_ sender: Any) {
        removeVideoPlayer()
        
        let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap , from: .main) as! FileDetailsViewController
        fileDetailsVC.file = file
        fileDetailsVC.viewModel = viewModel
        
        /*
         supportedInterfaceOrientations is not queried on setVC or push, because it assumes it will be the same as the previous view controller.
         However, on pop, it will query it.
         This is an elegant hack to tie everything together.
         */
        navigationController?.setViewControllers([fileDetailsVC, self], animated: false)
        navigationController?.popViewController(animated: false)
    }

    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        hideSpinner()
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            if status == .failed {
                showAlert(title: .error, message: "Sorry, can't play this video format.".localized())
            }
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

// MARK: - ImagePreviewViewControllerDelegate
// Used to hide the navigation bar in an image environment
extension FilePreviewViewController: ImagePreviewViewControllerDelegate {
    func imagePreviewViewControllerDidZoom(_ vc: ImagePreviewViewController, scale: CGFloat) {
        navigationController?.setNavigationBarHidden(scale > 1, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
// Used to hide the navigation bar in a webview environment
extension FilePreviewViewController: UIScrollViewDelegate {
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        navigationController?.setNavigationBarHidden(scale > 1, animated: true)
    }
}
