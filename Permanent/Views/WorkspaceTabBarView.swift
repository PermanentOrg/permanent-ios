//
//  WorkspaceTabBarView.swift
//  Permanent
//
//  Created by GitHub Copilot on 17.12.2025.
//

import SwiftUI

// MARK: - Custom Liquid Glass Tab Bar (NO TabView)
// This implementation uses HStack with custom buttons instead of TabView.
// TabView is fundamentally broken for our use case because it expects to manage
// content, but our content is managed by UIKit (DrawerViewController).

@available(iOS 26, *)
struct WorkspaceTabBarView: View {
    @ObservedObject var viewModel: WorkspaceTabViewModel
    @Namespace private var tabAnimation
    
    let onWorkspaceSelected: (WorkspaceType) -> Void
    let onPlusButtonTapped: () -> Void
    let onChecklistButtonTapped: () -> Void
    
    // Brand colors
    private let primaryColor = Color(red: 0.07, green: 0.11, blue: 0.29)
    private let secondaryColor = Color(red: 0.47, green: 0.49, blue: 0.57)
    
    var body: some View {
        HStack(spacing: 0) {
            // Workspace tab buttons (left side)
            HStack(spacing: 4) {
                ForEach(WorkspaceType.allCases, id: \.self) { workspace in
                    TabButton(
                        workspace: workspace,
                        isSelected: viewModel.selectedWorkspace == workspace,
                        namespace: tabAnimation,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewModel.selectedWorkspace = workspace
                        }
                        onWorkspaceSelected(workspace)
                    }
                }
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // Floating action buttons (right side)
            HStack(spacing: 12) {
                if viewModel.showPlusButton {
                    FloatingActionButton(
                        iconName: "plus",
                        primaryColor: primaryColor,
                        action: onPlusButtonTapped
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                if viewModel.showChecklistButton {
                    FloatingActionButton(
                        iconName: "checklist",
                        primaryColor: primaryColor,
                        action: onChecklistButtonTapped
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showPlusButton)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showChecklistButton)
        }
        .padding(.vertical, 12)
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .glassEffect(in: .capsule)
    }
}

// MARK: - Tab Button with matchedGeometryEffect

@available(iOS 26, *)
private struct TabButton: View {
    let workspace: WorkspaceType
    let isSelected: Bool
    let namespace: Namespace.ID
    let primaryColor: Color
    let secondaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: workspace.iconName)
                    .font(.system(size: 14, weight: .medium))
                
                if isSelected {
                    Text(workspace.title)
                        .font(.custom("Usual-Regular", size: 13))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundStyle(isSelected ? primaryColor : secondaryColor)
            .padding(.horizontal, isSelected ? 14 : 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                }
            }
        }
        .buttonStyle(TabButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Floating Action Button with Liquid Glass

@available(iOS 26, *)
private struct FloatingActionButton: View {
    let iconName: String
    let primaryColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(primaryColor)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .glassEffect(in: .circle)
        }
        .buttonStyle(FABButtonStyle())
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Custom Button Styles

@available(iOS 26, *)
private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

@available(iOS 26, *)
private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - iOS 16-25 Fallback (not used, kept for reference)
// On older iOS versions, the app will continue using the existing FABView
// No changes are made to the legacy behavior

#if DEBUG
@available(iOS 26, *)
struct WorkspaceTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = WorkspaceTabViewModel()
        viewModel.showPlusButton = true
        viewModel.showChecklistButton = true
        
        return VStack {
            Spacer()
            WorkspaceTabBarView(
                viewModel: viewModel,
                onWorkspaceSelected: { _ in },
                onPlusButtonTapped: {},
                onChecklistButtonTapped: {}
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
#endif
