//
//  LoadingScreenViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.03.2022.
//

import Foundation
import UIKit

class LoadingScreenViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide the navigation bar so the iOS 26 opaque dark-blue nav bar applied by
        // NavigationController.viewDidLoad() doesn't shift the full-screen logo downward.
        // This must be in viewDidLoad (not viewWillAppear) so the layout is resolved
        // with the bar hidden before the launch-screen → app transition renders the first frame.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
