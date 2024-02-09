//
//  DonateStorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.12.2023.

import SwiftUI
import UIKit

struct DonateStorageView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Donate", bundle: Bundle.main)
        let viewController = storyboard.instantiateViewController(identifier: "donate")
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
