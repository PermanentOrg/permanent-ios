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
        // Hide the nav bar, or the opaque one shifts the full-screen logo down. In `viewDidLoad`, not
        // `viewWillAppear`, so the layout resolves before the launch-screen transition's first frame.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
