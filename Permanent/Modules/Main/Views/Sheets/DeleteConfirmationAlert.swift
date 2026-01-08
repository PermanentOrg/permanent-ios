//
//  DeleteConfirmationAlert.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 4: Action Sheet Migration - Delete confirmation alert
//

import SwiftUI

// MARK: - DeleteConfirmationAlert

/// A SwiftUI view modifier that presents a delete confirmation alert.
/// Supports both single and batch delete with appropriate messaging.
@available(iOS 17, *)
struct DeleteConfirmationAlert: ViewModifier {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    let itemCount: Int
    let onConfirm: () -> Void
    
    // MARK: - Computed Properties
    
    private var title: String {
        itemCount == 1 ? "Delete Item" : "Delete Items"
    }
    
    private var message: String {
        "Are you sure you want to delete \(itemCount) item\(itemCount == 1 ? "" : "s")?"
    }
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                
                Button("Delete", role: .destructive) {
                    onConfirm()
                }
            } message: {
                Text(message)
            }
    }
}

// MARK: - View Extension

@available(iOS 17, *)
extension View {
    /// Presents a delete confirmation alert.
    /// - Parameters:
    ///   - isPresented: Binding to control presentation state
    ///   - itemCount: The number of items to delete (affects message)
    ///   - onConfirm: Callback triggered when deletion is confirmed
    /// - Returns: A view with the delete confirmation alert modifier applied
    func deleteConfirmationAlert(
        isPresented: Binding<Bool>,
        itemCount: Int,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationAlert(
            isPresented: isPresented,
            itemCount: itemCount,
            onConfirm: onConfirm
        ))
    }
    
    /// Presents a delete confirmation alert for a list of files.
    /// - Parameters:
    ///   - isPresented: Binding to control presentation state
    ///   - files: The files to delete (count used for message)
    ///   - onConfirm: Callback triggered when deletion is confirmed
    /// - Returns: A view with the delete confirmation alert modifier applied
    func deleteConfirmationAlert(
        isPresented: Binding<Bool>,
        files: [FileModel],
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationAlert(
            isPresented: isPresented,
            itemCount: files.count,
            onConfirm: onConfirm
        ))
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview("Single Item") {
    @Previewable @State var showAlert = true
    
    VStack {
        Text("Delete Single Item")
        Button("Show Alert") {
            showAlert = true
        }
    }
    .deleteConfirmationAlert(isPresented: $showAlert, itemCount: 1) {
        print("Deleted 1 item")
    }
}

@available(iOS 17, *)
#Preview("Multiple Items") {
    @Previewable @State var showAlert = true
    
    VStack {
        Text("Delete Multiple Items")
        Button("Show Alert") {
            showAlert = true
        }
    }
    .deleteConfirmationAlert(isPresented: $showAlert, itemCount: 5) {
        print("Deleted 5 items")
    }
}
