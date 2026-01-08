//
//  PermissionAlertView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 4: Action Sheet Migration - Permission request alerts
//

import SwiftUI

// MARK: - PermissionAlertView

/// A SwiftUI view modifier that presents a permission request alert.
/// Provides "Open Settings" action to navigate to app settings.
@available(iOS 17, *)
struct PermissionAlertView: ViewModifier {
    
    // MARK: - Properties
    
    @Binding var permissionType: PermissionAlertType?
    @Environment(\.openURL) private var openURL
    
    // MARK: - Computed Properties
    
    private var isPresented: Binding<Bool> {
        Binding(
            get: { permissionType != nil },
            set: { if !$0 { permissionType = nil } }
        )
    }
    
    private var alertTitle: String {
        permissionType?.title ?? ""
    }
    
    private var alertMessage: String {
        permissionType?.message ?? ""
    }
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .alert(alertTitle, isPresented: isPresented) {
                Button("Cancel", role: .cancel) { }
                
                Button("Open Settings") {
                    openAppSettings()
                }
            } message: {
                Text(alertMessage)
            }
    }
    
    // MARK: - Private Methods
    
    private func openAppSettings() {
        guard let settingsURL = URL(string: "App-Prefs:root") else {
            return
        }
        openURL(settingsURL)
    }
}

// MARK: - View Extension

@available(iOS 17, *)
extension View {
    /// Presents a permission alert based on the permission type.
    /// - Parameter permissionType: Binding to the optional permission type (nil hides alert)
    /// - Returns: A view with the permission alert modifier applied
    func permissionAlert(
        permissionType: Binding<PermissionAlertType?>
    ) -> some View {
        modifier(PermissionAlertView(permissionType: permissionType))
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview("Camera Permission") {
    @Previewable @State var permissionType: PermissionAlertType? = .camera
    
    VStack {
        Text("Camera Permission Alert")
        Button("Show Camera Alert") {
            permissionType = .camera
        }
        Button("Show Photo Library Alert") {
            permissionType = .photoLibrary
        }
        Button("Show Storage Alert") {
            permissionType = .storage
        }
    }
    .permissionAlert(permissionType: $permissionType)
}
