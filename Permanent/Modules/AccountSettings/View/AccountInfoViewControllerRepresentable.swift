//
//  AccountInfoUIViewControllerRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.02.2024.

import SwiftUI
import UIKit

struct AccountInfoViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController.create(withIdentifier: .accountInfo, from: .settings)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
