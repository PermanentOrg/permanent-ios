//
//  ShareExtensionNavigationController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.07.2022.
//

import UIKit

class ShareExtensionNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return [.all]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
