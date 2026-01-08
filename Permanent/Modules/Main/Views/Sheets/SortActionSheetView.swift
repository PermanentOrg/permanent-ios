//
//  SortActionSheetView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 4: Action Sheet Migration - Sort options confirmation dialog
//

import SwiftUI

// MARK: - SortActionSheetView

/// A SwiftUI view modifier that presents a sort options confirmation dialog.
/// Uses `.confirmationDialog` with checkmark indicators for the current selection.
@available(iOS 17, *)
struct SortActionSheetView: ViewModifier {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Binding var selection: SortOption
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Sort By",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                ForEach(SortOption.allCases, id: \.rawValue) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if selection == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
    }
}

// MARK: - View Extension

@available(iOS 17, *)
extension View {
    /// Presents a sort options confirmation dialog.
    /// - Parameters:
    ///   - isPresented: Binding to control presentation state
    ///   - selection: Binding to the current sort option selection
    /// - Returns: A view with the sort action sheet modifier applied
    func sortActionSheet(
        isPresented: Binding<Bool>,
        selection: Binding<SortOption>
    ) -> some View {
        modifier(SortActionSheetView(
            isPresented: isPresented,
            selection: selection
        ))
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    @Previewable @State var showSheet = true
    @Previewable @State var sortOption: SortOption = .nameAscending
    
    VStack {
        Text("Current Sort: \(sortOption.title)")
        Button("Show Sort Options") {
            showSheet = true
        }
    }
    .sortActionSheet(isPresented: $showSheet, selection: $sortOption)
}
