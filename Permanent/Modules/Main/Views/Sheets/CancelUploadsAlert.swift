//
//  CancelUploadsAlert.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 4: Action Sheet Migration - Cancel uploads confirmation alert
//

import SwiftUI

// MARK: - CancelUploadsAlert

/// A SwiftUI view modifier that presents a cancel uploads confirmation alert.
/// Displays the count of pending uploads and provides destructive cancel action.
@available(iOS 17, *)
struct CancelUploadsAlert: ViewModifier {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    let pendingCount: Int
    let onConfirm: () -> Void
    
    // MARK: - Computed Properties
    
    private var message: String {
        "Are you sure you want to cancel \(pendingCount) pending upload\(pendingCount == 1 ? "" : "s")?"
    }
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .alert("Cancel Uploads", isPresented: $isPresented) {
                Button("Keep Uploading", role: .cancel) { }
                
                Button("Cancel Uploads", role: .destructive) {
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
    /// Presents a cancel uploads confirmation alert.
    /// - Parameters:
    ///   - isPresented: Binding to control presentation state
    ///   - pendingCount: The number of pending uploads to cancel
    ///   - onConfirm: Callback triggered when cancellation is confirmed
    /// - Returns: A view with the cancel uploads alert modifier applied
    func cancelUploadsAlert(
        isPresented: Binding<Bool>,
        pendingCount: Int,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(CancelUploadsAlert(
            isPresented: isPresented,
            pendingCount: pendingCount,
            onConfirm: onConfirm
        ))
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview("Single Upload") {
    @Previewable @State var showAlert = true
    
    VStack {
        Text("Cancel Single Upload")
        Button("Show Alert") {
            showAlert = true
        }
    }
    .cancelUploadsAlert(isPresented: $showAlert, pendingCount: 1) {
        print("Cancelled 1 upload")
    }
}

@available(iOS 17, *)
#Preview("Multiple Uploads") {
    @Previewable @State var showAlert = true
    
    VStack {
        Text("Cancel Multiple Uploads")
        Button("Show Alert") {
            showAlert = true
        }
    }
    .cancelUploadsAlert(isPresented: $showAlert, pendingCount: 3) {
        print("Cancelled 3 uploads")
    }
}
