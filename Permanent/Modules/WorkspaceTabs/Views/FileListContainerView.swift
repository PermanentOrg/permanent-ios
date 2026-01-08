//
//  FileListContainerView.swift
//  Permanent
//
//  Created on 18.12.2025.
//

import SwiftUI

/// SwiftUI container for file listing (Private and Public workspaces)
/// Bridges to UIKit MainViewController for now, will be fully SwiftUI in the future
@available(iOS 26, *)
struct FileListContainerView: View {
    let filesViewModel: MyFilesViewModel
    let workspaceType: WorkspaceType
    
    var body: some View {
        UIViewControllerRepresentableWrapper(
            filesViewModel: filesViewModel,
            workspaceType: workspaceType
        )
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

/// Wraps UIKit MainViewController to display in SwiftUI
@available(iOS 26, *)
private struct UIViewControllerRepresentableWrapper: UIViewControllerRepresentable {
    let filesViewModel: MyFilesViewModel
    let workspaceType: WorkspaceType
    
    func makeUIViewController(context: Context) -> MainViewController {
        // Create MainViewController from storyboard
        let mainVC = UIViewController.create(
            withIdentifier: .main,
            from: .main
        ) as! MainViewController
        
        // Set the appropriate view model
        mainVC.viewModel = filesViewModel
        
        return mainVC
    }
    
    func updateUIViewController(_ uiViewController: MainViewController, context: Context) {
        // Update view model if needed
        if uiViewController.viewModel !== filesViewModel {
            uiViewController.viewModel = filesViewModel
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 26, *)
struct FileListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FileListContainerView(
            filesViewModel: MyFilesViewModel(),
            workspaceType: .private
        )
    }
}
#endif
