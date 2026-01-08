//
//  UploadOptionsSheet.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 4: Action Sheet Migration - Upload source selection dialog
//

import SwiftUI

// MARK: - UploadSource

/// Represents the available upload sources for file uploads.
enum UploadSource: String, CaseIterable {
    case photoLibrary = "Photo Library"
    case files = "Files"
    case camera = "Camera"
    
    /// The SF Symbol icon name for the upload source
    var iconName: String {
        switch self {
        case .photoLibrary:
            return "photo.on.rectangle"
        case .files:
            return "folder"
        case .camera:
            return "camera"
        }
    }
}

// MARK: - UploadOptionsSheet

/// A SwiftUI view modifier that presents an upload source selection dialog.
/// Provides options for Photo Library, Files, and Camera upload sources.
@available(iOS 17, *)
struct UploadOptionsSheet: ViewModifier {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    let onSelect: (UploadSource) -> Void
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Upload Files",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                ForEach(UploadSource.allCases, id: \.rawValue) { source in
                    Button {
                        onSelect(source)
                    } label: {
                        Label(source.rawValue, systemImage: source.iconName)
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose where to upload from")
            }
    }
}

// MARK: - View Extension

@available(iOS 17, *)
extension View {
    /// Presents an upload source selection confirmation dialog.
    /// - Parameters:
    ///   - isPresented: Binding to control presentation state
    ///   - onSelect: Callback triggered when a source is selected
    /// - Returns: A view with the upload options sheet modifier applied
    func uploadOptionsSheet(
        isPresented: Binding<Bool>,
        onSelect: @escaping (UploadSource) -> Void
    ) -> some View {
        modifier(UploadOptionsSheet(
            isPresented: isPresented,
            onSelect: onSelect
        ))
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    @Previewable @State var showSheet = true
    @Previewable @State var selectedSource: UploadSource?
    
    VStack {
        if let source = selectedSource {
            Text("Selected: \(source.rawValue)")
        } else {
            Text("No source selected")
        }
        Button("Show Upload Options") {
            showSheet = true
        }
    }
    .uploadOptionsSheet(isPresented: $showSheet) { source in
        selectedSource = source
    }
}
