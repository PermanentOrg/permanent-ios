//
//  PasswordUpdateViewControllerRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2025.


import SwiftUI
import UIKit

struct PasswordUpdateViewControllerRepresentable: UIViewControllerRepresentable {
    let title: String = "Change Password"
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController.create(withIdentifier: .passwordUpdate, from: .settings)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
