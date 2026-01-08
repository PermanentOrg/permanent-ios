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
    @State private var tabFrames: [WorkspaceType: CGRect] = [:]
    @State private var isDragging = false
    
    let onWorkspaceSelected: (WorkspaceType) -> Void
    let onPlusButtonTapped: () -> Void
    let onChecklistButtonTapped: () -> Void
    
    // Brand colors
    private let primaryColor = Color(red: 0.07, green: 0.11, blue: 0.29)
    private let secondaryColor = Color(red: 0.47, green: 0.49, blue: 0.57)
    
    var body: some View {
        HStack(spacing: 12) {
            // Workspace tabs in clean white container (iOS tab bar style)
            HStack(spacing: 0) {
                ForEach(WorkspaceType.allCases, id: \.self) { workspace in
                    TabButtonContent(
                        workspace: workspace,
                        isSelected: viewModel.selectedWorkspace == workspace,
                        namespace: tabAnimation,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: TabFramePreferenceKey.self,
                                    value: [workspace: geo.frame(in: .named("tabBar"))]
                                )
                        }
                    )
                    .onTapGesture {
                        selectWorkspace(workspace)
                    }
                }
            }
            .padding(.horizontal, 4)
            .coordinateSpace(name: "tabBar")
            .onPreferenceChange(TabFramePreferenceKey.self) { frames in
                tabFrames = frames
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        // Find which tab the finger is over
                        for (workspace, frame) in tabFrames {
                            if frame.contains(value.location) {
                                if viewModel.selectedWorkspace != workspace {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        viewModel.selectedWorkspace = workspace
                                    }
                                    // Haptic feedback on tab change
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                                break
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        // Find final tab and call selection callback
                        for (workspace, frame) in tabFrames {
                            if frame.contains(value.location) {
                                onWorkspaceSelected(workspace)
                                break
                            }
                        }
                    }
            )
            .padding(.vertical, 8)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
            )
            
            // Floating action buttons OUTSIDE the tab bar
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
        .padding(.trailing, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showPlusButton)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showChecklistButton)
        .opacity(viewModel.isHidden ? 0 : 1)
        .offset(y: viewModel.isHidden ? 100 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isHidden)
    }
    
    private func selectWorkspace(_ workspace: WorkspaceType) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            viewModel.selectedWorkspace = workspace
        }
        onWorkspaceSelected(workspace)
    }
}

// MARK: - Preference Key for Tab Frames

@available(iOS 26, *)
private struct TabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [WorkspaceType: CGRect] = [:]
    
    static func reduce(value: inout [WorkspaceType: CGRect], nextValue: () -> [WorkspaceType: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - Tab Button Content (without Button wrapper for drag gesture)

@available(iOS 26, *)
private struct TabButtonContent: View {
    let workspace: WorkspaceType
    let isSelected: Bool
    let namespace: Namespace.ID
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: workspace.iconName)
                .font(.system(size: 24, weight: .regular))
            
            Text(workspace.title)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isSelected ? primaryColor : secondaryColor)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Floating Action Button with Liquid Glass

@available(iOS 26, *)
private struct FloatingActionButton: View {
    let iconName: String
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(primaryColor)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.95))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
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

// MARK: - Interactive Glass Modifier (conditionally applied)

@available(iOS 26, *)
private struct InteractiveGlassModifier: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
        }
    }
}
#endif
