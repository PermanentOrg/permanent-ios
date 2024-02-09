//
//  ActivityFeedViewControllerRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.02.2024.

import SwiftUI
import UIKit

struct ActivityFeedViewControllerRepresentable: UIViewControllerRepresentable {
    let title: String = "Activity Feed"
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ActivityFeedViewController()
        viewController.viewModel = ActivityFeedViewModel()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
