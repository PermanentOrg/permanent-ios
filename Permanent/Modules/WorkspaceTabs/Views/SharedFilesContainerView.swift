//
//  SharedFilesContainerView.swift
//  Permanent
//
//  Created on 18.12.2025.
//

import SwiftUI

/// SwiftUI container for Shared workspace
/// Bridges to UIKit SharesViewController for now
@available(iOS 26, *)
struct SharedFilesContainerView: View {
    var body: some View {
        UIViewControllerRepresentableWrapper()
            .ignoresSafeArea(.all, edges: .bottom)
    }
}

/// Wraps UIKit SharesViewController to display in SwiftUI
@available(iOS 26, *)
private struct UIViewControllerRepresentableWrapper: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> SharesViewController {
        // Create SharesViewController from storyboard
        let sharesVC = UIViewController.create(
            withIdentifier: .shares,
            from: .share
        ) as! SharesViewController
        
        return sharesVC
    }
    
    func updateUIViewController(_ uiViewController: SharesViewController, context: Context) {
        // No updates needed for now
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 26, *)
struct SharedFilesContainerView_Previews: PreviewProvider {
    static var previews: some View {
        SharedFilesContainerView()
    }
}
#endif
