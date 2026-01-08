//
//  WorkspaceTabContainerView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Native SwiftUI TabView for Workspace Navigation
//
//  Replaces the custom UIKit-based workspace switching with native iOS TabView
//  Uses WorkspaceType enum for tab identification
//

import SwiftUI
import Foundation

@available(iOS 17, *)
struct WorkspaceTabContainerView: View {
    
    // MARK: - State
    
    /// Currently selected workspace tab
    @State private var selectedTab: WorkspaceType = .private
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Private Files Tab
            SwiftUIMainView(viewModel: MyFilesViewModel())
                .tabItem {
                    Label("Private", systemImage: "lock.fill")
                }
                .tag(WorkspaceType.private)
            
            // Shared Files Tab
            SharesContainerView()
                .tabItem {
                    Label("Shared", systemImage: "person.2.fill")
                }
                .tag(WorkspaceType.shared)
            
            // Public Files Tab
            SwiftUIMainView(viewModel: PublicFilesViewModel())
                .tabItem {
                    Label("Public", systemImage: "globe")
                }
                .tag(WorkspaceType.public)
        }
        .applyiOS26TabBarStyling()
    }
}

// MARK: - iOS 26+ Styling Extension

@available(iOS 17, *)
extension View {
    /// Applies iOS 26+ tab bar styling if available
    @ViewBuilder
    func applyiOS26TabBarStyling() -> some View {
        if #available(iOS 26, *) {
            // iOS 26+ can use custom tab bar styling
            // For now, use automatic style - can add custom glass effect later
            self.tabViewStyle(.automatic)
        } else {
            // iOS 17-25: use default TabView style
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17, *)
struct WorkspaceTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceTabContainerView()
    }
}
#endif
