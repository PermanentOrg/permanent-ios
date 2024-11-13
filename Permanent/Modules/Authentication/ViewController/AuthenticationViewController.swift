//
//  SignUpViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit
import SwiftUI

class AuthenticationViewController: BaseViewController<AuthViewModel> {
    @IBOutlet weak var container: UIView!
    var showRegisterView: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primary
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewModel = AuthViewModel()
        
        let childView = UIHostingController(rootView: AuthenticatorContainerView(viewModel: AuthenticatorContainerViewModel(contentType: showRegisterView ? .register : .login)))
        addChild(childView)
        childView.view.frame = container.bounds
        container.addSubview(childView.view)
        childView.didMove(toParent: self)
        
    }
}
