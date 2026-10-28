//
//  FilePreviewNavigationController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.03.2021.
//

import UIKit

protocol FilePreviewNavigationControllerDelegate: AnyObject {
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool)
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool)
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel)
}

class FilePreviewNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? (UIDevice.current.userInterfaceIdiom == .phone ? [.allButUpsideDown] : [.all])
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    weak var filePreviewNavDelegate: FilePreviewNavigationControllerDelegate?

    /// The opening animation from the preview; nil keeps the system one.
    var openTransition: UIViewControllerAnimatedTransitioning?
    /// The way back to the preview when the Info screen dismisses itself; nil keeps the system one.
    var closeTransition: UIViewControllerAnimatedTransitioning?
    
    var hasChanges: Bool = false {
        didSet {
            if hasChanges {
                filePreviewNavDelegate?.filePreviewNavigationControllerDidChange(self, hasChanges: hasChanges)
            }
        }
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        // Ensure navigation bar is always visible
        self.isNavigationBarHidden = false
        self.setNavigationBarHidden(false, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Explicitly show navigation bar
        setNavigationBarHidden(false, animated: false)
        navigationBar.isHidden = false
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .darkBlue
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed {
            filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension FilePreviewNavigationController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        openTransition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        closeTransition
    }
}
