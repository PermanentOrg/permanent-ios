//
//  AccountSettingsViewControllerRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.02.2024.

import SwiftUI
import UIKit

struct AccountSettingsViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController.create(withIdentifier: .accountSettings, from: .settings)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
