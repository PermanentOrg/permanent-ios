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
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: RoundedButton!
    
    let fileHelper = FileHelper()
    
    var file: FileViewModel!
    
    var playerItem: AVPlayerItem?
    var videoPlayer: AVPlayerViewController?
    var playerItemContext = 0
    
    let documentInteractionController = UIDocumentInteractionController()
    
    var pageVC: UIPageViewController!
    var hasChanges: Bool = false
    var recordLoaded: Bool = false {
        didSet {
            if recordLoaded == true {
                recordLoadedCB?(self)
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var recordLoadedCB: ((FilePreviewViewController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        videoPlayer?.player?.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        styleNavBar()
    }
    
    func loadVM() {
        guard recordLoaded == false else { return }
        
        if isViewLoaded {
            activityIndicator.startAnimating()
            if let url = URL(string: file.thumbnailURL) {
                thumbnailImageView.sd_setImage(with: url)
            }
        }
        
        if viewModel == nil || viewModel?.recordVO == nil {
            viewModel = FilePreviewViewModel(file: file)
            
            if file.type == .image, let url = URL(string: file.thumbnailURL2000) {
                loadImage(withURL: url)
            } else {
                viewModel?.getRecord(file: file, then: { record in
                    if record != nil {
                        self.loadRecord()
                    } else {
                        self.activityIndicator.stopAnimating()
                        self.thumbnailImageView.isHidden = true
                        
                        self.errorLabel.isHidden = false
                        self.retryButton.isHidden = false
                    }
                })
            }
        } else if file.type == .image, let url = URL(string: file.thumbnailURL2000) {
            loadImage(withURL: url)
        } else {
            loadRecord()
        }
    }
    
    func initUI() {
        styleNavBar()
        
        errorLabel.font = Text.style17.font
        errorLabel.textColor = .white
        errorLabel.isHidden = true
        retryButton.configureActionButtonUI(title: "Retry".localized(), bgColor: .tangerine, buttonHeight: 30)
        retryButton.setFont(Text.style10.font)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.isHidden = true

        let shareButton = UIBarButtonItem(image: UIImage(named: "more")!, style: .plain, target: self, action: #selector(showShareMenu(_:)))

        let infoButton = UIBarButtonItem(image: .info, style: .plain, target: self, action: #selector(infoButtonAction(_:)))
        navigationItem.rightBarButtonItems = [shareButton, infoButton]
        let leftButtonImage: UIImage!
        if #available(iOS 13.0, *) {
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        } else {
            leftButtonImage = UIImage(named: "close")
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        
        title = file.name
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .black
            navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = .black
        } else {
            navigationController?.navigationBar.barTintColor = .black
        }
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
        let fileType = FileType(rawValue: self.viewModel?.recordVO?.recordVO?.type ?? "") ?? .miscellaneous
        
        if let localURL = self.fileHelper.url(forFileNamed: fileName),
            let contentType = fileVO.contentType {
            switch fileType {
            case FileType.image:
                break
                
            case FileType.video:
                self.loadVideo(withURL: localURL, contentType: contentType)
                
            default:
                self.loadMisc(withURL: localURL)
            }
        } else if let downloadURLString = fileVO.downloadURL,
            let contentType = fileVO.contentType,
            let downloadURL = URL(string: downloadURLString) {
            switch fileType {
            case FileType.image:
                break
                
            case FileType.video:
                self.loadVideo(withURL: downloadURL, contentType: contentType)
                
            default:
                self.loadMisc(withURL: downloadURL)
            }
        } else {
            self.errorLabel.isHidden = false
            self.retryButton.isHidden = false
        }
        
        if recordLoaded != true {
            recordLoaded = true
        }
    }
    
    func loadImage(withURL url: URL) {
        let imagePreviewVC = ImagePreviewViewController()
        imagePreviewVC.delegate = self
        addChild(imagePreviewVC)
        imagePreviewVC.view.frame = view.bounds
        imagePreviewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Insert view under the spinner
        view.insertSubview(imagePreviewVC.view, at: 0)
        imagePreviewVC.didMove(toParent: self)
        imagePreviewVC.imageView.sd_setImage(with: url) { _, error, _, _ in
            self.activityIndicator.stopAnimating()
            self.thumbnailImageView.isHidden = true
            
            if error != nil {
                self.errorLabel.isHidden = false
                self.retryButton.isHidden = false

                imagePreviewVC.view.removeFromSuperview()
                imagePreviewVC.removeFromParent()
                imagePreviewVC.didMove(toParent: nil)
            } else {
                imagePreviewVC.newImageLoaded()
            }
        }
    }
    
    func loadVideo(withURL url: URL, contentType: String) {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let player = AVPlayer(playerItem: playerItem)
        videoPlayer = AVPlayerViewController()
        videoPlayer!.player = player
        
        self.playerItem = playerItem
        
        addChild(videoPlayer!)
        videoPlayer!.view.frame = view.bounds.insetBy(dx: 0, dy: 60)
        videoPlayer!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(videoPlayer!.view, at: 0)
        videoPlayer!.didMove(toParent: self)
        
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
    }
    
    func loadMisc(withURL url: URL) {
        let webView = setupWebView()
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func removeVideoPlayer() {
        videoPlayer?.player?.replaceCurrentItem(with: nil)
        
        videoPlayer?.willMove(toParent: nil)
        videoPlayer?.view.removeFromSuperview()
        videoPlayer?.removeFromParent()
    }
    
    // MARK: - Actions

    @objc func showShareMenu(_ sender: Any) {
        var actions: [PRMNTAction] = []
        
        actions.append(PRMNTAction(title: "Share to Another App".localized(), color: .primary, handler: { [self] action in
            shareWithOtherApps()
        })
        )
        
        if let publicURL = viewModel?.publicURL {
            actions.append(PRMNTAction(title: "Get Link".localized(), color: .primary, handler: { [self] action in
                share(url: publicURL)
            })
            )
        } else if self.file.permissions.contains(.ownership) {
            actions.append(PRMNTAction(title: "Share via Permanent".localized(), color: .primary, handler: { [self] action in
                if let file = self.viewModel?.file {
                    shareInApp(file: file)
                }
            })
            )
        }
    
        let actionSheet = PRMNTActionSheetViewController(title: "", actions: actions)
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func infoButtonAction(_ sender: Any) {
        let fileDetailsVC = UIViewController.create(withIdentifier: .fileDetailsOnTap, from: .main) as! FileDetailsViewController
        fileDetailsVC.file = viewModel?.file
        fileDetailsVC.viewModel = viewModel
        fileDetailsVC.delegate = self
        
        let navControl = FilePreviewNavigationController(rootViewController: fileDetailsVC)
        navControl.modalPresentationStyle = .fullScreen
        present(navControl, animated: false, completion: nil)
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        (navigationController as! FilePreviewNavigationController).filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        
        removeVideoPlayer()
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func retryButtonPressed(_ sender: Any) {
        errorLabel.isHidden = true
        retryButton.isHidden = true
        
        loadVM()
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            if status == .failed {
                self.errorLabel.isHidden = false
                self.retryButton.isHidden = false
                
                removeVideoPlayer()
            }
        }
    }
    
    // MARK: - Menu dismiss
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
    
    func shareWithOtherApps() {
        if let fileName = self.viewModel?.fileName(),
            let localURL = fileHelper.url(forFileNamed: fileName) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            })
            )

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
    
    func shareInApp(file: FileViewModel) {
        guard
            let shareVC = UIViewController.create(
                withIdentifier: .share,
                from: .share
            ) as? ShareViewController
        else {
            return
        }

        shareVC.sharedFile = file
        
        let shareNavController = FilePreviewNavigationController(rootViewController: shareVC)
        present(shareNavController, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension FilePreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
        
        self.errorLabel.isHidden = false
        self.retryButton.isHidden = false
        
        webView.removeFromSuperview()
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

extension FilePreviewViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges == true {
            self.hasChanges = true
        }
        
        dismiss(animated: true) {
            (self.navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: self.hasChanges)
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        let viewModel = (pageVC.viewControllers?.first as! FilePreviewViewController).viewModel
        title = viewModel?.name
        
        if hasChanges == true {
            self.hasChanges = true
        }
    }
}
