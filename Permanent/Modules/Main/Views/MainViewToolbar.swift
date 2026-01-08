//
//  MainViewToolbar.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 5 Part 2: SwiftUI ToolbarContent for MainView
//

import SwiftUI

// MARK: - MainViewToolbar

/// A SwiftUI ToolbarContent struct providing the main navigation toolbar items.
/// Includes back navigation, folder title, search, grid/list toggle, sort, and selection controls.
@available(iOS 17, *)
struct MainViewToolbar: ToolbarContent {
    
    // MARK: - Properties
    
    /// The main view state for reading/writing toolbar-related state
    @ObservedObject var state: MainViewState
    
    /// Callback for back navigation
    var onBackTapped: (() -> Void)?
    
    /// Callback for search toggle
    var onSearchToggled: (() -> Void)?
    
    // MARK: - Body
    
    var body: some ToolbarContent {
        // Leading: Back button (when not at root)
        ToolbarItem(placement: .navigationBarLeading) {
            leadingContent
        }
        
        // Principal: Current folder name
        ToolbarItem(placement: .principal) {
            principalContent
        }
        
        // Trailing: Action buttons
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            trailingContent
        }
    }
    
    // MARK: - Leading Content
    
    @ViewBuilder
    private var leadingContent: some View {
        if !state.isAtSwiftUIRoot {
            Button {
                onBackTapped?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
            .accessibilityLabel("Back")
            .accessibilityHint("Navigate to parent folder")
        } else {
            // Empty view when at root
            EmptyView()
        }
    }
    
    // MARK: - Principal Content
    
    @ViewBuilder
    private var principalContent: some View {
        if state.isSelecting {
            // Show selection count when in selection mode
            selectionCountView
        } else {
            // Show folder name
            Text(state.currentFolderDisplayName)
                .font(.custom("Usual-Medium", size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
        }
    }
    
    private var selectionCountView: some View {
        HStack(spacing: 4) {
            Text("\(state.selectedFiles.count)")
                .font(.custom("Usual-Bold", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(UIColor.primary))
                )
            
            Text("Selected".localized())
                .font(.custom("Usual-Medium", size: 15))
                .foregroundColor(Color(UIColor.darkBlue))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.selectedFiles.count) items selected")
    }
    
    // MARK: - Trailing Content
    
    @ViewBuilder
    private var trailingContent: some View {
        if state.isSelecting {
            // Cancel button when selecting
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    state.updateSelection(isSelecting: false)
                }
            } label: {
                Text("Cancel".localized())
                    .font(.custom("Usual-Medium", size: 15))
                    .foregroundColor(Color(UIColor.primary))
            }
            .accessibilityLabel("Cancel selection")
        } else {
            // Normal toolbar buttons
            normalTrailingButtons
        }
    }
    
    @ViewBuilder
    private var normalTrailingButtons: some View {
        // Search button
        Button {
            onSearchToggled?()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
        .accessibilityLabel("Search")
        .accessibilityHint("Search files and folders")
        
        // Grid/List toggle button
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                state.updateGridView(!state.isGridView)
            }
        } label: {
            Image(systemName: state.isGridView ? "list.bullet" : "square.grid.2x2")
                .font(.system(size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
        .accessibilityLabel(state.isGridView ? "Switch to list view" : "Switch to grid view")
        
        // Sort button
        Button {
            state.presentSortSheet()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
        .accessibilityLabel("Sort options")
        .accessibilityHint("Open sort options")
        
        // Select button
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                state.updateSelection(isSelecting: true)
            }
        } label: {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
        .accessibilityLabel("Select items")
        .accessibilityHint("Enter selection mode")
    }
}

// MARK: - MainViewToolbar Convenience Modifiers

@available(iOS 17, *)
extension View {
    
    /// Applies the MainViewToolbar to this view
    /// - Parameters:
    ///   - state: The MainViewState to bind to
    ///   - onBackTapped: Callback for back navigation
    ///   - onSearchToggled: Callback for search toggle
    /// - Returns: A view with the MainViewToolbar applied
    func mainViewToolbar(
        state: MainViewState,
        onBackTapped: (() -> Void)? = nil,
        onSearchToggled: (() -> Void)? = nil
    ) -> some View {
        self.toolbar {
            MainViewToolbar(
                state: state,
                onBackTapped: onBackTapped,
                onSearchToggled: onSearchToggled
            )
        }
    }
}

// MARK: - Compact Toolbar Variant

/// A more compact toolbar variant for use in narrower contexts
@available(iOS 17, *)
struct CompactMainViewToolbar: ToolbarContent {
    
    @ObservedObject var state: MainViewState
    var onBackTapped: (() -> Void)?
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !state.isAtSwiftUIRoot {
                Button {
                    onBackTapped?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back".localized())
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.darkBlue))
                }
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text(state.currentFolderDisplayName)
                .font(.custom("Usual-Medium", size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
                .lineLimit(1)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    state.updateGridView(!state.isGridView)
                } label: {
                    Label(
                        state.isGridView ? "List View" : "Grid View",
                        systemImage: state.isGridView ? "list.bullet" : "square.grid.2x2"
                    )
                }
                
                Button {
                    state.presentSortSheet()
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                
                Divider()
                
                Button {
                    state.updateSelection(isSelecting: true)
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
}

// MARK: - String Localization Extension

private extension String {
    /// Returns the localized version of this string
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Preview Provider

#if DEBUG
@available(iOS 17, *)
struct MainViewToolbar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List {
                Text("Content")
            }
            .toolbar {
                MainViewToolbar(
                    state: PreviewStateFactory.makeDefaultState(),
                    onBackTapped: { print("Back tapped") },
                    onSearchToggled: { print("Search toggled") }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Normal Mode")
        
        NavigationStack {
            List {
                Text("Content")
            }
            .toolbar {
                MainViewToolbar(
                    state: PreviewStateFactory.makeSelectionModeState(),
                    onBackTapped: { print("Back tapped") },
                    onSearchToggled: { print("Search toggled") }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Selection Mode")
    }
}

/// Factory for creating preview states
@available(iOS 17, *)
@MainActor
private enum PreviewStateFactory {
    static func makeDefaultState() -> MainViewState {
        let mock = PreviewFilesViewModel()
        return MainViewState(filesViewModel: mock)
    }
    
    static func makeSelectionModeState() -> MainViewState {
        let mock = PreviewFilesViewModel()
        let state = MainViewState(filesViewModel: mock)
        state.isSelecting = true
        state.selectedFiles = [1, 2, 3]
        return state
    }
}

/// Mock FilesViewModel for previews
@available(iOS 17, *)
private class PreviewFilesViewModel: FilesViewModel {
    override init() {
        super.init()
    }
}
#endif
