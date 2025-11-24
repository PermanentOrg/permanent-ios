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
    
    var hasChanges: Bool = false {
        didSet {
            if hasChanges {
                filePreviewNavDelegate?.filePreviewNavigationControllerDidChange(self, hasChanges: hasChanges)
            }
        }
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed {
            filePreviewNavDelegate?.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        }
    }
}
