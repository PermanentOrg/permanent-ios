//
//  SharesContainerView.swift
//  Permanent
//
//  Created on 19.12.2025
//  UIKit-to-SwiftUI Migration: Shares Container
//
//  UIViewControllerRepresentable wrapper for SharesViewController
//  Allows embedding the UIKit SharesViewController in SwiftUI TabView
//

import SwiftUI
import UIKit

@available(iOS 17, *)
struct SharesContainerView: UIViewControllerRepresentable {
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> SharesViewController {
        // Create SharesViewController from storyboard
        let sharesVC = UIViewController.create(
            withIdentifier: .shares,
            from: .share
        ) as! SharesViewController
        
        return sharesVC
    }
    
    func updateUIViewController(_ uiViewController: SharesViewController, context: Context) {
        // No updates needed - the view controller manages its own state
    }
}
