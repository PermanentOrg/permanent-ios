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
}

class FilePreviewNavigationController: UINavigationController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? (UIDevice.current.userInterfaceIdiom == .phone ? [.allButUpsideDown] : [.all])
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    weak var filePreviewNavDelegate: FilePreviewNavigationControllerDelegate?
    
    var hasChanges: Bool = false
    
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
}
