//
//  PhotoPickerView.swift
//  Permanent
//
//  Created on 19.12.2025.
//

import SwiftUI
import UIKit
import PhotosUI

/// A SwiftUI view that wraps the native PhotosPicker for selecting photos and videos.
/// Supports multi-selection with configurable maximum selection count.
@available(iOS 17.0, *)
struct PhotoPickerView: View {
    
    // MARK: - Properties
    
    /// The currently selected photo items
    @Binding var selectedItems: [PhotosPickerItem]
    
    /// Maximum number of items that can be selected (nil for unlimited)
    let maxSelectionCount: Int?
    
    /// Callback when selection is complete
    let onComplete: ([PhotosPickerItem]) -> Void
    
    /// Filter for the types of media to show
    let filter: PHPickerFilter
    
    /// The label to display on the picker button
    let label: String
    
    // MARK: - Initialization
    
    /// Creates a new PhotoPickerView
    /// - Parameters:
    ///   - selectedItems: Binding to the selected photo items
    ///   - maxSelectionCount: Maximum number of items that can be selected (nil for unlimited)
    ///   - filter: Filter for media types (default: images and videos)
    ///   - label: Label for the picker button
    ///   - onComplete: Callback when selection is complete
    init(
        selectedItems: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        filter: PHPickerFilter = .any(of: [.images, .videos]),
        label: String = "Select Photos",
        onComplete: @escaping ([PhotosPickerItem]) -> Void
    ) {
        self._selectedItems = selectedItems
        self.maxSelectionCount = maxSelectionCount
        self.filter = filter
        self.label = label
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelectionCount,
            matching: filter,
            photoLibrary: .shared()
        ) {
            Label(label, systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            if !newValue.isEmpty {
                onComplete(newValue)
            }
        }
    }
}

// MARK: - Inline Photo Picker

/// An inline photo picker that can be embedded directly in views
@available(iOS 17.0, *)
struct InlinePhotoPickerView: View {
    
    // MARK: - Properties
    
    @Binding var selectedItems: [PhotosPickerItem]
    let maxSelectionCount: Int?
    let filter: PHPickerFilter
    let onComplete: ([PhotosPickerItem]) -> Void
    
    // MARK: - Initialization
    
    init(
        selectedItems: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        filter: PHPickerFilter = .any(of: [.images, .videos]),
        onComplete: @escaping ([PhotosPickerItem]) -> Void
    ) {
        self._selectedItems = selectedItems
        self.maxSelectionCount = maxSelectionCount
        self.filter = filter
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelectionCount,
            matching: filter,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 12) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Tap to select photos")
                    .font(.headline)
                
                if let max = maxSelectionCount {
                    Text("Maximum \(max) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            if !newValue.isEmpty {
                onComplete(newValue)
            }
        }
    }
}

// MARK: - Helper Extensions

@available(iOS 17.0, *)
extension PhotoPickerView {
    
    /// Creates a photo-only picker
    static func photosOnly(
        selectedItems: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        onComplete: @escaping ([PhotosPickerItem]) -> Void
    ) -> PhotoPickerView {
        PhotoPickerView(
            selectedItems: selectedItems,
            maxSelectionCount: maxSelectionCount,
            filter: .images,
            label: "Select Photos",
            onComplete: onComplete
        )
    }
    
    /// Creates a video-only picker
    static func videosOnly(
        selectedItems: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        onComplete: @escaping ([PhotosPickerItem]) -> Void
    ) -> PhotoPickerView {
        PhotoPickerView(
            selectedItems: selectedItems,
            maxSelectionCount: maxSelectionCount,
            filter: .videos,
            label: "Select Videos",
            onComplete: onComplete
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Photo Picker Button") {
    struct PreviewWrapper: View {
        @State private var selectedItems: [PhotosPickerItem] = []
        
        var body: some View {
            VStack(spacing: 20) {
                PhotoPickerView(
                    selectedItems: $selectedItems,
                    maxSelectionCount: 5
                ) { items in
                    print("Selected \(items.count) items")
                }
                
                Text("Selected: \(selectedItems.count) items")
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

@available(iOS 17.0, *)
#Preview("Inline Photo Picker") {
    struct PreviewWrapper: View {
        @State private var selectedItems: [PhotosPickerItem] = []
        
        var body: some View {
            VStack(spacing: 20) {
                InlinePhotoPickerView(
                    selectedItems: $selectedItems,
                    maxSelectionCount: 10
                ) { items in
                    print("Selected \(items.count) items")
                }
                
                Text("Selected: \(selectedItems.count) items")
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
