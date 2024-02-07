//
//  InvitesViewControllerRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.02.2024.

import Foundation

import SwiftUI
import UIKit

struct InvitesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        guard let viewController = UIViewController.create(withIdentifier: .invitations, from: .invitations) as? InvitesViewController else {
            return UIViewController()
        }
        viewController.viewModel = InviteViewModel()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
