//
//  WebViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.02.2021.
//

import UIKit
import WebKit
import AVKit
import PDFKit
import SwiftUI
import SDWebImage

class FilePreviewViewController: BaseViewController<FilePreviewViewModel> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? [.allButUpsideDown] : [.all]
    }
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: RoundedButton!
    let overlayView = UIView(frame: .zero)
    
    let fileHelper = FileHelper()
    
    var file: FileModel!
    
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
    var closeAction: (() -> Void)?
    
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
    
    var imagePreviewVC: ImagePreviewViewController?
    
    func loadVM() {
        guard recordLoaded == false else { return }
        
        if isViewLoaded {
            activityIndicator.startAnimating()
            if let url = URL(string: file.preferredThumbnailURL) {
                thumbnailImageView.sd_setImage(with: url)
            }
        }
        
        if viewModel == nil || viewModel?.recordVO == nil {
            viewModel = FilePreviewViewModel(file: file)
            
            if file.type == .image, let thumbnailURLString = file.preferredThumbnailURL {
                loadThumbnailPreview(urlString: thumbnailURLString)
            }
            
            viewModel?.getRecord(file: file, then: { [weak self] record in
                if record != nil {
                    self?.loadRecord()
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.thumbnailImageView.isHidden = true
                    
                    self?.errorLabel.isHidden = false
                    self?.retryButton.isHidden = false
                }
            })
        } else if file.type == .image, let thumbnailURLString = file.preferredThumbnailURL {
            loadThumbnailPreview(urlString: thumbnailURLString)
        } else {
            loadRecord()
        }
    }

    func initUI() {
        styleNavBar()
        
        errorLabel.font = TextFontStyle.style17.font
        errorLabel.textColor = .white
        errorLabel.isHidden = true
        retryButton.configureActionButtonUI(title: "Retry".localized(), bgColor: .tangerine, buttonHeight: 30)
        retryButton.setFont(TextFontStyle.style10.font)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.isHidden = true

        let shareButton = UIBarButtonItem(image: UIImage(named: "more")!, style: .plain, target: self, action: #selector(showShareMenu(_:)))
        navigationItem.rightBarButtonItem = shareButton
        
        // If opened from notification, add close button
        if closeAction != nil {
            let closeButton = UIBarButtonItem(
                image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)),
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )
            navigationItem.leftBarButtonItem = closeButton
        }
        
        title = file.name
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.standardAppearance.backgroundColor = .black
        navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = .black
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
                // Use download URL for full-res; fall back to thumbnail URL
                let fullResURL = fileVO.downloadURL ?? self.viewModel?.fileThumbnailURL()
                if let urlString = fullResURL, let url = URL(string: urlString) {
                    self.loadImage(withURL: url)
                }
        
            case FileType.video:
                self.loadVideo(withURL: localURL, contentType: contentType)
                
            case FileType.audio:
                self.loadAudio(withURL: localURL, contentType: contentType)
                
            case FileType.pdf:
                self.loadPDF(withURL: localURL)
                
            default:
                self.loadMisc(withURL: localURL)
            }
        } else if let downloadURLString = fileVO.downloadURL,
            let contentType = fileVO.contentType,
            let downloadURL = URL(string: downloadURLString) {
            switch fileType {
            case FileType.image:
                // Use download URL for full-resolution image
                self.loadImage(withURL: downloadURL)
                
            case FileType.video:
                self.loadVideo(withURL: downloadURL, contentType: contentType)
                
            case FileType.audio:
                self.loadAudio(withURL: downloadURL, contentType: contentType)
                
            case FileType.pdf:
                self.loadPDF(withURL: downloadURL)
                
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
    
    /// Loads the 256px thumbnail into the zoomable image preview as a quick placeholder.
    private func loadThumbnailPreview(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let previewVC = ImagePreviewViewController()
        previewVC.delegate = self
        self.imagePreviewVC = previewVC
        
        addChild(previewVC)
        previewVC.view.frame = view.bounds
        previewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(previewVC.view, at: 0)
        previewVC.didMove(toParent: self)
        
        previewVC.imageView.sd_setImage(with: url) { [weak self] _, error, _, _ in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.thumbnailImageView.isHidden = true
            
            if error != nil {
                self.errorLabel.isHidden = false
                self.retryButton.isHidden = false
                self.removeImagePreviewVC()
            } else {
                previewVC.newImageLoaded()
            }
        }
    }
    
    /// Upgrades the existing image preview from thumbnail to full-resolution using the download URL.
    /// SDWebImage caches the full-res image, so subsequent opens load instantly from disk.
    private func upgradeToFullResolution(urlString: String) {
        guard let url = URL(string: urlString),
              let previewVC = self.imagePreviewVC else { return }
        
        // Check if SDWebImage already has this URL cached (from a previous open)
        let cachedFromMemory = SDImageCache.shared.imageFromMemoryCache(forKey: urlString) != nil
        
        previewVC.imageView.sd_setImage(
            with: url,
            placeholderImage: previewVC.imageView.image,
            options: [.avoidAutoSetImage, .retryFailed],
            progress: nil
        ) { [weak previewVC] image, _, cacheType, _ in
            guard let previewVC = previewVC, let image = image else { return }
            
            if cachedFromMemory || cacheType == .memory {
                // Cached in memory — swap immediately, no animation needed
                previewVC.imageView.image = image
                previewVC.newImageLoaded()
            } else {
                // Downloaded or loaded from disk — crossfade for smooth transition
                UIView.transition(with: previewVC.imageView, duration: 0.3, options: .transitionCrossDissolve) {
                    previewVC.imageView.image = image
                } completion: { _ in
                    previewVC.newImageLoaded()
                }
            }
        }
    }
    
    private func removeImagePreviewVC() {
        imagePreviewVC?.view.removeFromSuperview()
        imagePreviewVC?.removeFromParent()
        imagePreviewVC?.didMove(toParent: nil)
        imagePreviewVC = nil
    }
    
    func loadImage(withURL url: URL) {
        if imagePreviewVC != nil {
            // Image preview already showing thumbnail — upgrade to full-res
            upgradeToFullResolution(urlString: url.absoluteString)
        } else {
            // No preview yet (e.g. record already loaded) — load directly
            let previewVC = ImagePreviewViewController()
            previewVC.delegate = self
            self.imagePreviewVC = previewVC
            
            addChild(previewVC)
            previewVC.view.frame = view.bounds
            previewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(previewVC.view, at: 0)
            previewVC.didMove(toParent: self)
            
            previewVC.imageView.sd_setImage(with: url) { [weak self] _, error, _, _ in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.thumbnailImageView.isHidden = true
                
                if error != nil {
                    self.errorLabel.isHidden = false
                    self.retryButton.isHidden = false
                    self.removeImagePreviewVC()
                } else {
                    previewVC.newImageLoaded()
                }
            }
        }
    }
    
    func loadPDF(withURL url: URL) {
        DispatchQueue.global().async {
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async { [self] in
                    let pdfView = PDFView()
                    pdfView.autoScales = true

                    pdfView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(pdfView)

                    pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
                    pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
                    pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                    pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

                    pdfView.document = document
                }
            }
        }
    }
        
    func loadVideo(withURL url: URL, contentType: String) {
        loadAV(withURL: url, contentType: contentType)
    }
    
    func loadAudio(withURL url: URL, contentType: String) {
        loadAV(withURL: url, contentType: contentType)
        
        let playButton = UIButton(type: .custom)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(named: "play.circle"), for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(playAudioFile(_:)), for: .touchUpInside)
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .black
        view.addSubview(overlayView)
        overlayView.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor, constant: 0),
            overlayView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 0),
            overlayView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 0),
            overlayView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 0),
            playButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
    }
    
    func loadAV(withURL url: URL, contentType: String) {
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

    
    @objc func playAudioFile(_ sender: UIButton) {
        overlayView.isHidden = true
        
        videoPlayer?.entersFullScreenWhenPlaybackBegins = true
        videoPlayer?.player?.play()
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

    @objc func closeButtonTapped() {
        closeAction?()
    }
    
    @objc func showShareMenu(_ sender: Any) {
        var menuItems: [FileMenuViewModel.MenuItem] = []
        
        // Share to Permanent - only for files with ownership
        if file.permissions.contains(.ownership) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToPermanent, action: nil))
        }
        
        // Share to another app - for files with share permission (not folders)
        if file.permissions.contains(.share) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToAnotherApp, action: { [self] in
                shareWithOtherApps()
            }))
        }
        
        // Publish on the web - for files with delete permission
        if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .publish, action: { [self] in
                publishAction()
            }))
        }
        
        // Download - for files with read permission (not folders)
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .download, action: { [weak self] in
                guard let self = self else { return }
                self.downloadFile()
            }))
        }
        
        let swiftUIView = FileMoreMenuView(
            fileViewModel: file,
            menuItems: menuItems,
            onDismiss: { [weak self] in
                // Only dismiss the menu overlay, not the preview
                self?.presentedViewController?.dismiss(animated: true)
            },
            onShareManagementRequested: { [weak self] file in
                // Don't dismiss the preview - just dismiss the menu and present share management on top
                if let hostingController = self?.presentedViewController {
                    hostingController.dismiss(animated: true) {
                        self?.presentShareManagement(for: file)
                    }
                }
            },
            downloadHandler: { [weak self] fileModel, completion in
                guard let self = self, let record = self.viewModel?.recordVO else {
                    completion(nil, NSError(domain: "FilePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Record not available"]))
                    return
                }
                
                self.viewModel?.download(record, fileType: fileModel.type, onFileDownloaded: { url, error in
                    completion(url, error)
                })
            }
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear
        
        present(hostingController, animated: true)
    }
    
    private func presentShareManagement(for file: FileModel) {
        let shareContainerView = ShareContainerView(fileModel: file)
        let hostingController = UIHostingController(rootView: shareContainerView)
        hostingController.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(hostingController, animated: true)
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
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func htmlBody(withContent content: String) -> String {
        return "<html><body style=\"width:\(UIScreen.main.scale * view.frame.width);height:\(UIScreen.main.scale * view.frame.height);background-color:#000000;margin:0;padding:0;\">\(content)</body></html>"
    }
    
    func shareWithOtherApps() {
        let fileExtension = (file.uploadFileName as NSString).pathExtension
        let fileName = !fileExtension.isEmpty ? "\(file.name).\(fileExtension)" : file.name
        
        if let localURL = fileHelper.url(forFileNamed: fileName) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            }))

            present(preparingAlert, animated: true) {
                if let record = self.viewModel?.recordVO {
                    self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { url, error in
                        if let url = url {
                            self.dismiss(animated: true) {
                                self.share(url: url)
                            }
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func downloadFile() {
        guard let record = viewModel?.recordVO else {
            showErrorAlert(message: "Unable to download file")
            return
        }
        
        if let menuHostingController = presentedViewController {
            menuHostingController.dismiss(animated: true) {
                self.startDownload(record: record)
            }
        } else {
            startDownload(record: record)
        }
    }
    
    private func startDownload(record: RecordVO) {
        let preparingAlert = UIAlertController(title: "Downloading...".localized(), message: nil, preferredStyle: .alert)
        preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { [weak self] _ in
            self?.viewModel?.cancelDownload()
        }))
        
        present(preparingAlert, animated: true) {
            self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { [weak self] url, error in
                guard let self = self else { return }
                
                self.dismiss(animated: true) {
                    if url != nil {
                        let successAlert = UIAlertController(
                            title: "Download complete".localized(),
                            message: nil,
                            preferredStyle: .alert
                        )
                        self.present(successAlert, animated: true)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            successAlert.dismiss(animated: true)
                        }
                    } else {
                        let errorMessage = error?.localizedDescription ?? "Failed to download file"
                        self.showErrorAlert(message: errorMessage)
                    }
                }
            })
        }
    }
    
    func publishAction() {
        let presentPublishView: () -> Void = { [weak self] in
            guard let self = self else { return }
            
            var hostingController: UIHostingController<PublishView>?
            
            let publishView = PublishView(
                fileName: self.file.name,
                isFolder: self.file.type.isFolder,
                thumbnailURL: self.file.thumbnailURL,
                thumbnailURL2000: self.file.thumbnailURL2000,
                onPublish: { [weak self] in
                    hostingController?.dismiss(animated: false) {
                        self?.publish()
                    }
                },
                onDismiss: {
                    hostingController?.dismiss(animated: false)
                }
            )
            
            hostingController = UIHostingController(rootView: publishView)
            hostingController?.modalPresentationStyle = .overFullScreen
            hostingController?.modalTransitionStyle = .crossDissolve
            hostingController?.view.backgroundColor = .clear
            
            if let controller = hostingController {
                self.present(controller, animated: false)
            }
        }
        
        if let presented = presentedViewController {
            presented.dismiss(animated: true) {
                DispatchQueue.main.async {
                    presentPublishView()
                }
            }
        } else {
            presentPublishView()
        }
    }
    
    private func publish() {
        showSpinner()
        
        // Get the current archive number
        guard let archiveNbr = AuthenticationManager.shared.session?.selectedArchive?.archiveNbr else {
            hideSpinner()
            showErrorAlert(message: "Unable to publish file")
            return
        }
        
        // First, get the public root folder
        let filesRepository = FilesRepository()
        filesRepository.getPublicRoot(archiveNbr: archiveNbr) { [weak self] (folder, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.hideSpinner()
                self.showErrorAlert(message: error.localizedDescription)
                return
            }
            
            guard let publicRootFolder = folder else {
                self.hideSpinner()
                self.showErrorAlert(message: "Unable to get public folder")
                return
            }
            
            // Now relocate (copy) the file to the public folder
            filesRepository.relocate(
                files: [self.file],
                folderLinkId: publicRootFolder.folderLinkId,
                isCopy: true
            ) { error in
                self.hideSpinner()
                
                if let error = error {
                    self.showErrorAlert(message: error.localizedDescription)
                } else {
                    if self.file.type.isFolder {
                        self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder published successfully".localized())
                    } else {
                        self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "File published successfully".localized())
                    }
                }
            }
        }
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
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        // This controller manages the preview, so forward the request through its navigation controller
        (navigationController as? FilePreviewNavigationController)?.filePreviewNavDelegate?.filePreviewNavigationControllerRequestsDownload(self, file: file)
    }
}
