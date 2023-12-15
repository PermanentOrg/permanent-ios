//
//  DonateStorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.12.2023.

import SwiftUI
import UIKit

struct DonateStorageView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = DonateViewController()
        let storyboard = UIStoryboard(name: "Donate", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "donate")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
