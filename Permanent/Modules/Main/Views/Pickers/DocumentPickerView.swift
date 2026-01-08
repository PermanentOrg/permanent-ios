//
//  DocumentPickerView.swift
//  Permanent
//
//  Created on 19.12.2025.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A SwiftUI view that wraps UIDocumentPickerViewController for selecting documents.
/// Supports multi-selection and various file types.
@available(iOS 17.0, *)
struct DocumentPickerView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The content types to allow for selection
    let contentTypes: [UTType]
    
    /// Whether multiple documents can be selected
    let allowsMultipleSelection: Bool
    
    /// Callback when documents are picked
    let onDocumentsPicked: ([URL]) -> Void
    
    /// Callback when the picker is cancelled
    let onCancel: () -> Void
    
    // MARK: - Initialization
    
    /// Creates a new DocumentPickerView
    /// - Parameters:
    ///   - contentTypes: The content types to allow (default: all items and content)
    ///   - allowsMultipleSelection: Whether multiple selection is allowed (default: true)
    ///   - onDocumentsPicked: Callback when documents are selected
    ///   - onCancel: Callback when picker is cancelled
    init(
        contentTypes: [UTType] = [.item, .content],
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.contentTypes = contentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentsPicked = onDocumentsPicked
        self.onCancel = onCancel
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        // MARK: - UIDocumentPickerDelegate
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Start accessing security-scoped resources
            let accessibleURLs = urls.compactMap { url -> URL? in
                guard url.startAccessingSecurityScopedResource() else {
                    return nil
                }
                return url
            }
            
            parent.onDocumentsPicked(accessibleURLs)
            
            // Note: Caller is responsible for calling stopAccessingSecurityScopedResource()
            // when done with the URLs
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 17.0, *)
extension DocumentPickerView {
    
    /// Creates a document picker for images only
    static func images(
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DocumentPickerView {
        DocumentPickerView(
            contentTypes: [.image],
            allowsMultipleSelection: allowsMultipleSelection,
            onDocumentsPicked: onDocumentsPicked,
            onCancel: onCancel
        )
    }
    
    /// Creates a document picker for PDFs only
    static func pdfs(
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DocumentPickerView {
        DocumentPickerView(
            contentTypes: [.pdf],
            allowsMultipleSelection: allowsMultipleSelection,
            onDocumentsPicked: onDocumentsPicked,
            onCancel: onCancel
        )
    }
    
    /// Creates a document picker for videos only
    static func videos(
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DocumentPickerView {
        DocumentPickerView(
            contentTypes: [.movie, .video],
            allowsMultipleSelection: allowsMultipleSelection,
            onDocumentsPicked: onDocumentsPicked,
            onCancel: onCancel
        )
    }
    
    /// Creates a document picker for all file types
    static func allFiles(
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> DocumentPickerView {
        DocumentPickerView(
            contentTypes: [.item, .content, .data],
            allowsMultipleSelection: allowsMultipleSelection,
            onDocumentsPicked: onDocumentsPicked,
            onCancel: onCancel
        )
    }
}

// MARK: - Document Picker Modifier

@available(iOS 17.0, *)
struct DocumentPickerModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    let contentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onDocumentsPicked: ([URL]) -> Void
    let onCancel: () -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                DocumentPickerView(
                    contentTypes: contentTypes,
                    allowsMultipleSelection: allowsMultipleSelection,
                    onDocumentsPicked: { urls in
                        isPresented = false
                        onDocumentsPicked(urls)
                    },
                    onCancel: {
                        isPresented = false
                        onCancel()
                    }
                )
                .ignoresSafeArea()
            }
    }
}

@available(iOS 17.0, *)
extension View {
    
    /// Presents a document picker sheet
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - contentTypes: The content types to allow
    ///   - allowsMultipleSelection: Whether multiple selection is allowed
    ///   - onDocumentsPicked: Callback when documents are selected
    ///   - onCancel: Callback when picker is cancelled
    func documentPicker(
        isPresented: Binding<Bool>,
        contentTypes: [UTType] = [.item, .content],
        allowsMultipleSelection: Bool = true,
        onDocumentsPicked: @escaping ([URL]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            DocumentPickerModifier(
                isPresented: isPresented,
                contentTypes: contentTypes,
                allowsMultipleSelection: allowsMultipleSelection,
                onDocumentsPicked: onDocumentsPicked,
                onCancel: onCancel
            )
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Document Picker") {
    struct PreviewWrapper: View {
        @State private var showPicker = false
        @State private var selectedURLs: [URL] = []
        
        var body: some View {
            VStack(spacing: 20) {
                Button("Select Documents") {
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
                
                if !selectedURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Files:")
                            .font(.headline)
                        
                        ForEach(selectedURLs, id: \.absoluteString) { url in
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding()
            .documentPicker(
                isPresented: $showPicker,
                allowsMultipleSelection: true
            ) { urls in
                selectedURLs = urls
            } onCancel: {
                print("Picker cancelled")
            }
        }
    }
    
    return PreviewWrapper()
}
