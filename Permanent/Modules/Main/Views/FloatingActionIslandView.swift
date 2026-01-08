//
//  FloatingActionIslandView.swift
//  Permanent
//
//  Created for UIKit-to-SwiftUI Migration - Phase 5 Part 3
//  iOS 26 Liquid Glass floating action island for file selection actions
//  Created 19.12.2025
//

import SwiftUI

// MARK: - Floating Action Island View

/// A floating action bar that appears when files are selected.
/// Uses iOS 26+ Liquid Glass effect with fallback for iOS 17-25.
@available(iOS 17, *)
struct FloatingActionIslandView: View {
    @ObservedObject var state: MainViewState
    
    /// Callback for move action (handled by coordinator)
    var onMoveAction: (() -> Void)?
    /// Callback for copy action (handled by coordinator)
    var onCopyAction: (() -> Void)?
    /// Callback for share action (handled by coordinator)
    var onShareAction: (() -> Void)?
    /// Callback for download action (handled by coordinator)
    var onDownloadAction: (() -> Void)?
    
    // MARK: - Private Properties
    
    private let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var isVisible: Bool {
        state.selectedFiles.count > 0
    }
    
    private var selectedCount: Int {
        state.selectedFiles.count
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer()
            
            if isVisible {
                actionIslandContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(springAnimation, value: isVisible)
    }
    
    // MARK: - Action Island Content
    
    @ViewBuilder
    private var actionIslandContent: some View {
        VStack(spacing: 8) {
            // Selection count badge
            selectionBadge
            
            // Action buttons bar
            actionBar
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Selection Badge
    
    private var selectionBadge: some View {
        Text("\(selectedCount) selected")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.darkBlue)
            )
    }
    
    // MARK: - Action Bar
    
    @ViewBuilder
    private var actionBar: some View {
        HStack(spacing: 0) {
            // Move button
            IslandActionButton(
                icon: "folder",
                label: "Move",
                action: handleMove
            )
            
            // Copy button
            IslandActionButton(
                icon: "doc.on.doc",
                label: "Copy",
                action: handleCopy
            )
            
            // Share button
            IslandActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                action: handleShare
            )
            
            // Download button
            IslandActionButton(
                icon: "arrow.down.circle",
                label: "Download",
                action: handleDownload
            )
            
            // Delete button (destructive)
            IslandActionButton(
                icon: "trash",
                label: "Delete",
                isDestructive: true,
                action: handleDelete
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .modifier(GlassEffectModifier())
    }
    
    // MARK: - Actions
    
    private func handleMove() {
        state.moveSelectedFiles()
        onMoveAction?()
    }
    
    private func handleCopy() {
        state.copySelectedFiles()
        onCopyAction?()
    }
    
    private func handleShare() {
        onShareAction?()
    }
    
    private func handleDownload() {
        onDownloadAction?()
    }
    
    private func handleDelete() {
        state.presentDeleteConfirmationForSelection()
    }
}

// MARK: - Island Action Button

@available(iOS 17, *)
private struct IslandActionButton: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    private var foregroundColor: Color {
        isDestructive ? .red : Color.darkBlue
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(IslandButtonStyle(isDestructive: isDestructive))
    }
}

// MARK: - Island Button Style

@available(iOS 17, *)
private struct IslandButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Effect Modifier

/// Applies iOS 26+ Liquid Glass effect with fallback for older versions
@available(iOS 17, *)
private struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17, *)
struct FloatingActionIslandView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock state for preview
        FloatingActionIslandPreviewWrapper()
    }
}

@available(iOS 17, *)
private struct FloatingActionIslandPreviewWrapper: View {
    @State private var mockSelectedCount = 3
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack {
                Text("Select some files")
                    .font(.title)
                
                Spacer()
                
                // Mock action island (without actual state)
                MockFloatingActionIsland(selectedCount: mockSelectedCount)
            }
        }
    }
}

@available(iOS 17, *)
private struct MockFloatingActionIsland: View {
    let selectedCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Selection count badge
            Text("\(selectedCount) selected")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.07, green: 0.11, blue: 0.29))
                )
            
            // Action buttons bar
            HStack(spacing: 0) {
                ForEach([
                    ("folder", "Move", false),
                    ("doc.on.doc", "Copy", false),
                    ("square.and.arrow.up", "Share", false),
                    ("arrow.down.circle", "Download", false),
                    ("trash", "Delete", true)
                ], id: \.0) { icon, label, isDestructive in
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                        
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(isDestructive ? .red : Color(red: 0.07, green: 0.11, blue: 0.29))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
#endif
