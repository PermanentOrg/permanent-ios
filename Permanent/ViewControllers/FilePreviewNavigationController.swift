//
//  FilePreviewNavigationController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.03.2021.
//

import UIKit

protocol FilePreviewNavigationControllerDelegate: class {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
