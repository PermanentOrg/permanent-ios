//
//  SwiftUIHelpers.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 29.05.2023.

import UIKit
import SwiftUI

class SelfSizingHostingController<Content>: UIHostingController<Content> where Content: View {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize()
    }
}

extension UIView {
    
    func addSubview(_ view: AnyView) {
        let hostingController = SelfSizingHostingController(rootView: view)
        self.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
