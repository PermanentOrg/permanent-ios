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

    /// Set by the public gallery: its records live in a FOREIGN archive but are public, so
    /// the V2 read applies there too. See FilePreviewViewModel.allowsForeignDetail.
    var allowsForeignStelaDetail: Bool = false

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

    let imageStateOverlay = ImagePreviewStateOverlayView()

    var recordLoadedCB: ((FilePreviewViewController) -> Void)?
    var closeAction: (() -> Void)?
    /// Set when the user cancels an in-progress download so the (still-firing) download
    /// completion doesn't surface a spurious error after the cancel.
    private var didCancelDownload = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupImageStateOverlay()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateShares(_:)), name: ShareLinkViewModel.didUpdateSharesNotifName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateShares(_:)), name: ShareItemViewModel.didUpdateSharesNotifName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReachabilityChanged(_:)), name: ReachabilityManager.reachabilityDidChangeNotifName, object: nil)
        // The `.playback` session is activated lazily, only for audio and video: previewing an image
        // or PDF must not interrupt the user's background music.
    }

    /// True once this preview activated the shared `.playback` session. Gates the deinit
    /// deactivation, so an image or PDF preview doesn't poke a session it never touched.
    private var didActivatePlaybackAudioSession = false

    /// One-shot: the A/V original failed to load and we retried with the converted rendition.
    /// Without this the retry would re-enter the same `.failed` handler and loop.
    private var didFallBackToConvertedAV = false

    /// Set by a pager that owns the audio session across its cached pages. Non-nil means this
    /// controller must not deactivate in deinit, or an evicted page silences the playing one.
    var onDidActivatePlaybackAudioSession: (() -> Void)?

    /// Switches the shared session to playback, for previews that can play media. Released in deinit
    /// or by the pager, so other apps' audio resumes afterwards.
    private func activatePlaybackAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            didActivatePlaybackAudioSession = true
            onDidActivatePlaybackAudioSession?()
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopObservingPlayerItem()
        // Only self-deactivate a standalone preview, and only if we activated it. Under a pager, a
        // cached page's deinit deactivating here would silence another page that is still playing.
        if didActivatePlaybackAudioSession, onDidActivatePlaybackAudioSession == nil {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if pendingAudioReveal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startAudioBlurRevealIfPossible()
            }
        }
    }
    
    var imagePreviewVC: ImagePreviewViewController?
    
    func loadVM() {
        guard recordLoaded == false else { return }
        imageStateOverlay.isImageContent = file.type == .image

        if isViewLoaded {
            activityIndicator.startAnimating()
            if file.type == .audio {
                // Audio goes straight from black and a spinner to the blurred QuickTime artwork: no neutral
                // glow, and no thumbnail, which would be a file-type icon rather than content.
                thumbnailImageView.isHidden = true
            } else {
                if let url = URL(string: file.preferredThumbnailURL) {
                    thumbnailImageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed]) { [weak self] image, _, _, _ in
                        guard let self = self, self.file.type != .image else { return }
                        self.previewBlurAvailable = image != nil
                        self.imageStateOverlay.setSourceImage(image)
                    }
                }
                if file.type != .image {
                    // Videos blur their first frame; other non-image files use the neutral placeholder, since
                    // blurring a file-type icon reads as a glowing blob. `type` is unreliable, so extension too.
                    activityIndicator.stopAnimating()
                    if isLikelyVideoFile {
                        imageStateOverlay.render(.loadingFullRes(hasThumbnail: file.preferredThumbnailURL != nil))
                    } else {
                        imageStateOverlay.render(.loadingFullRes(hasThumbnail: false))
                    }
                }
            }
        }

        if viewModel == nil || viewModel?.recordVO == nil {
            viewModel = FilePreviewViewModel(file: file,
                                            allowsForeignDetail: allowsForeignStelaDetail)
            bindImagePreviewState()

            if file.type == .image {
                var thumbnailURL = file.preferredThumbnailURL
                #if DEBUG
                if debugForceNoThumbnail { thumbnailURL = nil }
                #endif
                let canLoad = viewModel?.startImageLoad(hasThumbnail: thumbnailURL != nil) ?? true
                guard canLoad else {
                    // Offline (S7): show whatever the cache has under the blur, but start no network load.
                    activityIndicator.stopAnimating()
                    if let thumbnailURLString = thumbnailURL {
                        loadThumbnailPreview(urlString: thumbnailURLString, cacheOnly: true)
                    }
                    return
                }
                if let thumbnailURLString = thumbnailURL {
                    loadThumbnailPreview(urlString: thumbnailURLString)
                }
            }

            viewModel?.getRecord(file: file, then: { [weak self] record in
                if record != nil {
                    self?.loadRecord()
                } else {
                    self?.activityIndicator.stopAnimating()

                    if self?.file.type == .image {
                        self?.viewModel?.imageLoadDidFail(error: nil)
                    } else {
                        self?.showPreviewLoadFailure()
                    }
                }
            })
        } else if file.type == .image, let thumbnailURLString = file.preferredThumbnailURL {
            bindImagePreviewState()
            loadThumbnailPreview(urlString: thumbnailURLString)
        } else {
            loadRecord()
        }
    }

    // MARK: - Image preview state handling

    private func setupImageStateOverlay() {
        imageStateOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageStateOverlay)
        NSLayoutConstraint.activate([
            imageStateOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            imageStateOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageStateOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageStateOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        imageStateOverlay.onRetryTapped = { [weak self] in
            self?.retryPreviewLoad()
        }
    }

    private func bindImagePreviewState() {
        viewModel?.onImagePreviewStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.imageStateOverlay.render(state)
            }
        }
        // Non-image types drive the overlay directly (the view model's state machine stays .idle
        // for them) — syncing it here would hide the placeholder rendered in loadVM.
        if file.type == .image, let state = viewModel?.imagePreviewState {
            imageStateOverlay.render(state)
        }
    }

    private func retryPreviewLoad() {
        if file.type == .image {
            guard viewModel?.retryRequested() == true else { return }
            resumeImageLoad()
            return
        }
        // Non-image: the offline card stays until connectivity returns (S7 behaviour);
        // tapping it while still offline is a no-op. When online, re-run the load.
        guard ReachabilityManager.shared.isConnected else { return }
        nonImageAwaitingReconnect = false
        imageStateOverlay.render(.idle)
        recordLoaded = false
        // Drop the cached record: replaying it fails identically, and a document waiting on its PDF
        // rendition only recovers once a fresh fetch reports the new file.
        viewModel?.recordVO = nil
        loadVM()
    }

    /// Failure and offline card for non-image previews, which have no view-model state machine.
    /// Offline waits for reconnect and auto-retries; an online failure offers tap-to-retry.
    private func showPreviewLoadFailure() {
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
        let connected = ReachabilityManager.shared.isConnected
        nonImageAwaitingReconnect = !connected
        // Match the backdrop `loadVM()` chose, or the preview flips between two looks on every retry.
        // A "not ready yet" document should still look like it is loading, not like another screen.
        let hasBlur = previewBlurAvailable && (file.type == .image || isLikelyVideoFile)
        imageStateOverlay.render(connected ? .failed(hasThumbnail: hasBlur)
                                           : .offline(hasThumbnail: hasBlur))
    }

    private func resumeImageLoad() {
        if viewModel?.recordVO == nil {
            viewModel?.getRecord(file: file, then: { [weak self] record in
                if record != nil {
                    self?.loadRecord()
                } else {
                    self?.viewModel?.imageLoadDidFail(error: nil)
                }
            })
        } else {
            loadRecord()
        }
    }

    @objc private func onReachabilityChanged(_ notification: Notification) {
        if file.type == .image {
            guard viewModel?.connectivityRestored() == true else { return }
            resumeImageLoad()
        } else if nonImageAwaitingReconnect, ReachabilityManager.shared.isConnected {
            retryPreviewLoad()
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
        
        if let localURL = self.fileHelper.url(forFileNamed: FileHelper.recordScopedName(fileName, recordId: file.recordId)),
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
                // WebKit refuses spreadsheet MIME types and turns the navigation into a download, rendering
                // nothing — so preview the PDF access copy through PDFKit. Download still gets the original.
                if let accessCopyURL = self.viewModel?.pdfAccessCopyURL() {
                    self.loadPDF(withURL: accessCopyURL)
                } else {
                    // No rendition available, but still prefer the inline URL: `downloadURL` carries an
                    // `attachment` content disposition and so guarantees a download rather than a render.
                    self.loadMisc(withURL: fileVO.fileURL.flatMap { URL(string: $0) } ?? downloadURL)
                }
            }
        } else if file.type == .image {
            self.viewModel?.imageLoadDidFail(error: nil)
        } else {
            self.showPreviewLoadFailure()
        }

        if recordLoaded != true {
            recordLoaded = true
        }
    }
    
    /// Loads the 256px thumbnail into the zoomable image preview as a quick placeholder.
    /// With `cacheOnly` set, no network request is made (used while offline — S7).
    private func loadThumbnailPreview(urlString: String, cacheOnly: Bool = false) {
        guard let url = URL(string: urlString) else { return }

        let previewVC = ImagePreviewViewController()
        previewVC.delegate = self
        self.imagePreviewVC = previewVC

        addChild(previewVC)
        previewVC.view.frame = view.bounds
        previewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(previewVC.view, at: 0)
        previewVC.didMove(toParent: self)

        // .retryFailed: without it, one transient failure puts the URL on SDWebImage's
        // session-wide failed-URL blacklist and every later attempt fails instantly.
        previewVC.imageView.sd_setImage(with: url, placeholderImage: nil, options: cacheOnly ? [.fromCacheOnly] : [.retryFailed]) { [weak self] _, error, _, _ in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.thumbnailImageView.isHidden = true

            if error != nil {
                if !cacheOnly {
                    // Thumbnail-specific failure: the full-res pipeline may still deliver,
                    // so this keeps the loading state rather than painting the failed card.
                    self.viewModel?.thumbnailLoadDidFail(error: error)
                }
            } else {
                previewVC.newImageLoaded()
                self.imageStateOverlay.setSourceImage(previewVC.imageView.image)
                if !cacheOnly {
                    self.viewModel?.thumbnailDidLoad()
                }
            }
        }
    }
    
    /// Upgrades the existing image preview from thumbnail to full-resolution using the download URL.
    /// SDWebImage caches the full-res image, so subsequent opens load instantly from disk.
    private func upgradeToFullResolution(urlString: String) {
        guard let url = URL(string: urlString),
              let previewVC = self.imagePreviewVC else { return }

        previewVC.imageView.sd_setImage(
            with: url,
            placeholderImage: previewVC.imageView.image,
            options: [.avoidAutoSetImage, .retryFailed],
            progress: nil
        ) { [weak self, weak previewVC] image, error, _, _ in
            guard let previewVC = previewVC, let image = image, error == nil else {
                // Full-res failed (S6) — keep the thumbnail beneath the blur so retry can reuse it.
                self?.viewModel?.imageLoadDidFail(error: error)
                return
            }

            // Swap the image and recompute its geometry atomically beneath the opaque overlay, and only
            // then fade the blur — otherwise the sharp image renders in stale geometry and appears to zoom.
            previewVC.imageView.image = image
            previewVC.newImageLoaded()
            self?.viewModel?.fullResDidLoad()
        }
    }
    
    private func removeImagePreviewVC() {
        imagePreviewVC?.view.removeFromSuperview()
        imagePreviewVC?.removeFromParent()
        imagePreviewVC?.didMove(toParent: nil)
        imagePreviewVC = nil
    }
    
    #if DEBUG
    /// QA hook: launch with `--slowImageLoad=5` to delay the full-res upgrade by N seconds,
    /// making the blur + spinner loading state observable on fast networks.
    private var debugFullResDelay: TimeInterval {
        guard let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--slowImageLoad=") }),
              let seconds = Double(arg.split(separator: "=").last ?? "") else { return 0 }
        return seconds
    }

    /// QA hook: launch with `--failFullResOnce` to make the first full-res load attempt fail,
    /// exercising S6 (load failed) and, after tap-to-retry, S8 → success.
    private static var debugFailFullResConsumed = false
    private var debugShouldFailFullRes: Bool {
        guard CommandLine.arguments.contains("--failFullResOnce"), !Self.debugFailFullResConsumed else { return false }
        Self.debugFailFullResConsumed = true
        return true
    }

    /// QA hook: launch with `--forceNoThumbnail` to pretend the record has no 256px thumbnail,
    /// exercising the neutral-placeholder loading state (logo, glow and spinner).
    var debugForceNoThumbnail: Bool {
        CommandLine.arguments.contains("--forceNoThumbnail")
    }
    #endif

    func loadImage(withURL url: URL) {
        if imagePreviewVC != nil {
            // Image preview already showing thumbnail — upgrade to full-res
            #if DEBUG
            if debugShouldFailFullRes {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.viewModel?.imageLoadDidFail(error: NSError(domain: "QA.failFullResOnce", code: -1))
                }
                return
            }
            if debugFullResDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + debugFullResDelay) { [weak self] in
                    self?.upgradeToFullResolution(urlString: url.absoluteString)
                }
                return
            }
            #endif
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
            
            let startDirectLoad = { [weak self, weak previewVC] in
                guard let previewVC = previewVC else { return }
                previewVC.imageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed]) { _, error, _, _ in
                    guard let self = self else { return }
                    self.activityIndicator.stopAnimating()
                    self.thumbnailImageView.isHidden = true

                    if error != nil {
                        self.viewModel?.imageLoadDidFail(error: error)
                    } else {
                        previewVC.newImageLoaded()
                        self.viewModel?.fullResDidLoad()
                    }
                }
            }
            #if DEBUG
            if debugFullResDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + debugFullResDelay, execute: startDirectLoad)
                return
            }
            #endif
            startDirectLoad()
        }
    }
    
    func loadPDF(withURL url: URL) {
        DispatchQueue.global().async {
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async { [self] in
                    let pdfView = PDFView()
                    pdfView.autoScales = true

                    pdfView.translatesAutoresizingMaskIntoConstraints = false
                    // Insert behind the loading overlay so its fade-out cross-dissolves into the document;
                    // `addSubview` would cover the fade and snap the spinner away.
                    view.insertSubview(pdfView, at: 0)
                    // Hide the storyboard thumbnail, or it floats over the scrolling document now that the
                    // PDF view sits at the back.
                    thumbnailImageView.isHidden = true

                    pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
                    pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
                    pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                    pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

                    pdfView.document = document
                    imageStateOverlay.render(.loaded)

                    // autoScales leaves the document scrolled partway down the first page;
                    // jump to the top of page 1 once the document view has laid out.
                    DispatchQueue.main.async {
                        guard let firstPage = document.page(at: 0) else { return }
                        pdfView.layoutDocumentView()
                        let pageHeight = firstPage.bounds(for: pdfView.displayBox).height
                        pdfView.go(to: PDFDestination(page: firstPage, at: CGPoint(x: 0, y: pageHeight)))
                    }
                }
            } else {
                DispatchQueue.main.async { [self] in
                    showPreviewLoadFailure()
                }
            }
        }
    }
        
    func loadVideo(withURL url: URL, contentType: String) {
        activatePlaybackAudioSession()
        // file.type from the listing is unreliable (often .miscellaneous), so the
        // blurred placeholder is rendered here, where the record type is authoritative.
        showVideoLoadingPlaceholder()
        #if DEBUG
        // --slowImageLoad also postpones the video player, keeping the blurred
        // placeholder observable on fast networks.
        if debugFullResDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + debugFullResDelay) { [weak self] in
                self?.loadAV(withURL: url, contentType: contentType)
            }
            return
        }
        #endif
        loadAV(withURL: url, contentType: contentType)
    }

    private var isLikelyVideoFile: Bool {
        if file.type == .video { return true }
        let name = file.uploadFileName.isEmpty ? file.name : file.uploadFileName
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "3gp", "webm", "mts"]
        return videoExtensions.contains((name as NSString).pathExtension.lowercased())
    }

    private func showVideoLoadingPlaceholder() {
        let thumbnail = thumbnailImageView.image ?? imagePreviewVC?.imageView.image
        previewBlurAvailable = thumbnail != nil
        imageStateOverlay.setSourceImage(thumbnail)
        imageStateOverlay.render(.loadingFullRes(hasThumbnail: thumbnail != nil))
        activityIndicator.stopAnimating()
    }

    /// Initial play affordance, because the player's own controls stay hidden until the first tap
    /// and the video otherwise looks like a still. Dark backdrop for contrast over bright footage.
    private lazy var videoPlayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        button.layer.cornerRadius = 36
        button.accessibilityIdentifier = "videoPlayButton"
        button.addTarget(self, action: #selector(playVideoTapped(_:)), for: .touchUpInside)
        return button
    }()

    private func showVideoPlayButton() {
        guard videoPlayButton.superview == nil else { return }
        view.addSubview(videoPlayButton)
        NSLayoutConstraint.activate([
            videoPlayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoPlayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            videoPlayButton.widthAnchor.constraint(equalToConstant: 72),
            videoPlayButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    @objc private func playVideoTapped(_ sender: UIButton) {
        videoPlayButton.removeFromSuperview()
        videoPlayer?.player?.play()
    }
    
    func loadAudio(withURL url: URL, contentType: String) {
        activatePlaybackAudioSession()
        loadAV(withURL: url, contentType: contentType)
        // Audio has no frames for `isReadyForDisplay`, so snapshot the player's QuickTime artwork
        // behind an opaque cover and blur the snapshot — the artwork is never sharp before the blur.
        audioRevealStarted = false
        let cover = UIView()
        cover.backgroundColor = .black
        cover.frame = view.bounds
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let playerView = videoPlayer?.view {
            view.insertSubview(cover, aboveSubview: playerView)
        }
        audioCover = cover

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startAudioBlurRevealIfPossible()
        }

        let playButton = UIButton(type: .custom)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        playButton.tintColor = .white
        // Lighter circle than the video affordance — the audio backdrop is always black.
        playButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        playButton.layer.cornerRadius = 36
        playButton.addTarget(self, action: #selector(playAudioFile(_:)), for: .touchUpInside)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.isHidden = true   // revealed together with the sharp artwork
        view.addSubview(overlayView)
        overlayView.addSubview(playButton)

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor, constant: 0),
            overlayView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 0),
            overlayView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 0),
            overlayView.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 0),
            playButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 72),
            playButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    func loadAV(withURL url: URL, contentType: String) {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        let player = AVPlayer(playerItem: playerItem)
        videoPlayer = AVPlayerViewController()
        videoPlayer!.player = player

        self.playerItem = playerItem
        startObservingPlayerItem(playerItem)

        addChild(videoPlayer!)
        videoPlayer!.view.frame = view.bounds.insetBy(dx: 0, dy: 60)
        videoPlayer!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(videoPlayer!.view, at: 0)
        videoPlayer!.didMove(toParent: self)

        // `isReadyForDisplay` is the moment the first frame can render, unlike `status` or
        // `likelyToKeepUp`, which fire mid-buffering. It never fires for audio-only items.
        readyForDisplayObservation = videoPlayer!.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] playerVC, _ in
            guard playerVC.isReadyForDisplay else { return }
            DispatchQueue.main.async {
                self?.imageStateOverlay.render(.loaded)
                // `AVPlayerViewController` has no public API to surface its controls without a tap, so show
                // our own affordance; the native controls take over once playback starts.
                self?.showVideoPlayButton()
            }
        }
        // If playback starts through the player's own controls, drop our affordance.
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard player.timeControlStatus != .paused else { return }
            DispatchQueue.main.async {
                self?.videoPlayButton.removeFromSuperview()
            }
        }

        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
    }

    private var isObservingPlayerItem = false
    private var readyForDisplayObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var audioCover: UIView?
    private var pendingAudioReveal = false
    private var audioRevealStarted = false
    /// Whether a blurred thumbnail/frame is available to show behind the failure/offline card.
    private var previewBlurAvailable = false
    /// A non-image preview is parked in the offline state, awaiting reconnect to auto-retry.
    private var nonImageAwaitingReconnect = false

    // Do not add a "wait for the PDF rendition" retry loop here: it trades one honest failure card
    // for a minute-long spinner. Retry re-fetches the record, which picks the rendition up.

    /// Snapshots the player's artwork and runs the blur-to-sharp reveal. `drawHierarchy` crashes on
    /// windowless child-controller views, so an offscreen preloaded page waits for `viewDidAppear`.
    private func startAudioBlurRevealIfPossible() {
        // Both the loadAudio timer and the viewDidAppear deferred path can call this;
        // run the reveal exactly once to avoid a double snapshot / re-blur flicker.
        guard let playerView = videoPlayer?.view, audioCover != nil, !audioRevealStarted else { return }
        guard playerView.window != nil else {
            pendingAudioReveal = true
            return
        }
        pendingAudioReveal = false
        audioRevealStarted = true

        let snapshot = UIGraphicsImageRenderer(bounds: playerView.bounds).image { _ in
            playerView.drawHierarchy(in: playerView.bounds, afterScreenUpdates: true)
        }
        imageStateOverlay.setSourceImage(snapshot)
        imageStateOverlay.render(.loadingFullRes(hasThumbnail: true))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            self.audioCover?.removeFromSuperview()
            self.audioCover = nil
            self.imageStateOverlay.render(.loaded)
            self.overlayView.isHidden = false
        }
    }

    private func startObservingPlayerItem(_ item: AVPlayerItem) {
        stopObservingPlayerItem()
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: &playerItemContext)
        isObservingPlayerItem = true
    }

    private func stopObservingPlayerItem() {
        readyForDisplayObservation?.invalidate()
        readyForDisplayObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        guard isObservingPlayerItem, let item = playerItem else { return }
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)
        isObservingPlayerItem = false
    }

    
    @objc func playAudioFile(_ sender: UIButton) {
        overlayView.isHidden = true
        imageStateOverlay.render(.loaded)

        videoPlayer?.entersFullScreenWhenPlaybackBegins = true
        videoPlayer?.player?.play()
    }
    
    func loadMisc(withURL url: URL) {
        // A misc file's web view may hold playable media, or be a media file the server mis-typed.
        // Activate the playback session so it is audible and ignores the ring/silent switch.
        activatePlaybackAudioSession()
        let webView = setupWebView()

        // `WKWebView.load(URLRequest)` silently blanks on `file://` URLs, so a downloaded local file
        // must go through `loadFileURL`. Remote URLs still use a normal request.
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }
    
    func removeVideoPlayer() {
        stopObservingPlayerItem()
        videoPlayButton.removeFromSuperview()
        audioCover?.removeFromSuperview()
        audioCover = nil
        videoPlayer?.player?.replaceCurrentItem(with: nil)

        videoPlayer?.willMove(toParent: nil)
        videoPlayer?.view.removeFromSuperview()
        videoPlayer?.removeFromParent()
        videoPlayer = nil
        playerItem = nil
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

    @objc private func onDidUpdateShares(_ notification: Notification) {
        if let shareLinkVM = notification.object as? ShareLinkViewModel,
           file.recordId == shareLinkVM.fileViewModel.recordId,
           file.folderLinkId == shareLinkVM.fileViewModel.folderLinkId {
            file.accessRole = shareLinkVM.fileViewModel.accessRole
            file.minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
            return
        }

        guard let updatedFileModel = notification.userInfo?["fileModel"] as? FileModel,
              file.recordId == updatedFileModel.recordId,
              file.folderLinkId == updatedFileModel.folderLinkId else {
            return
        }

        file.accessRole = updatedFileModel.accessRole
        file.minArchiveVOS = updatedFileModel.minArchiveVOS
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

        let status: AVPlayerItem.Status?
        if keyPath == #keyPath(AVPlayerItem.status) {
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)
            } else {
                status = .unknown
            }
        } else {
            status = nil
        }

        // AVPlayerItem.status KVO may be delivered on a background thread; hop to main
        // before touching any UIKit state.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.thumbnailImageView.isHidden = true

            if status == .failed {
                self.stopObservingPlayerItem()
                self.removeVideoPlayer()

                // Retry once with the converted rendition before declaring failure. Cheaper than a synchronous
                // `AVAsset.isPlayable` probe on main: only a genuinely unplayable original pays anything.
                if !self.didFallBackToConvertedAV,
                   let converted = self.viewModel?.convertedAVFileVO(),
                   let url = URL(string: converted.downloadURL) {
                    self.didFallBackToConvertedAV = true
                    self.loadAV(withURL: url, contentType: converted.contentType ?? "")
                    return
                }

                self.showPreviewLoadFailure()
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
        
        if let localURL = fileHelper.url(forFileNamed: FileHelper.recordScopedName(fileName, recordId: file.recordId)) {
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
        didCancelDownload = false
        let preparingAlert = UIAlertController(title: "Downloading...".localized(), message: nil, preferredStyle: .alert)
        preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { [weak self] _ in
            self?.didCancelDownload = true
            self?.viewModel?.cancelDownload()
        }))

        present(preparingAlert, animated: true) {
            self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { [weak self] url, error in
                guard let self = self else { return }

                // Dismiss the alert specifically: `self.dismiss` tears down the whole preview screen once the
                // cancel tap has already dismissed the alert.
                preparingAlert.dismiss(animated: true) {
                    if self.didCancelDownload {
                        return
                    }
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

        // Publish = copy the item into the public workspace root.
        let onPublishResult: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.hideSpinner()
            if let error = error {
                self.showErrorAlert(message: error.localizedDescription)
            } else {
                let title = self.file.type.isFolder ? "Folder published successfully".localized() : "File published successfully".localized()
                self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: title)
            }
        }

        // An own-archive record publishing via the V2 copy resolves its public destination through the
        // archives search. Any resolution failure falls back to the V1 getPublicRoot lookup.
        if viewModel?.canPublishViaStelaCopy == true {
            viewModel?.resolvePublicRootFolderIdV2 { [weak self] publicRootFolderId in
                guard let self = self else { return }
                if let publicRootFolderId = publicRootFolderId {
                    self.viewModel?.copyRecordV2(destinationFolderId: publicRootFolderId, completion: onPublishResult)
                } else {
                    self.publishViaV1PublicRoot(onPublishResult: onPublishResult)
                }
            }
            return
        }

        publishViaV1PublicRoot(onPublishResult: onPublishResult)
    }

    /// The V1 destination lookup, kept as the failsafe for the V2 public-root path. A -1 folderId
    /// routes to relocate rather than posting "-1".
    private func publishViaV1PublicRoot(onPublishResult: @escaping (Error?) -> Void) {
        guard let archiveNbr = AuthenticationManager.shared.session?.selectedArchive?.archiveNbr else {
            hideSpinner()
            showErrorAlert(message: "Unable to publish file")
            return
        }
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
            if self.viewModel?.canPublishViaStelaCopy == true, publicRootFolder.folderId > 0 {
                self.viewModel?.copyRecordV2(destinationFolderId: String(publicRootFolder.folderId), completion: onPublishResult)
            } else {
                filesRepository.relocate(files: [self.file], folderLinkId: publicRootFolder.folderLinkId, isCopy: true, completion: onPublishResult)
            }
        }
    }

}

// MARK: - WKNavigationDelegate
extension FilePreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        thumbnailImageView.isHidden = true
        imageStateOverlay.render(.loaded)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.removeFromSuperview()
        showPreviewLoadFailure()
    }

    /// `didFail navigation:` only fires after a response is committed, so a load WebKit turns into
    /// a download reports here instead. Unimplemented, spreadsheets hung on the loading overlay.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.removeFromSuperview()
        showPreviewLoadFailure()
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
