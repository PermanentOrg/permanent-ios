//
//  PhotoLibraryPickerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14/08/2025.
//

import PhotosUI
import SwiftUI

struct PhotoLibraryPickerView: View {
    let onCompletion: @MainActor ([SelectedUploadFile]) -> Void
    let onCancel: @MainActor () -> Void

    @State private var isPickerPresented = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var hasPresentedPicker = false
    @State private var hasCompletedFlow = false
    @State private var isImporting = false

    var body: some View {
        ZStack {
            Color.clear
            if isImporting {
                LoadingOverlay()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
        .allowsHitTesting(isImporting)
        .animation(.easeInOut(duration: 0.3), value: isImporting)
        .task {
            guard hasPresentedPicker == false else {
                return
            }

            hasPresentedPicker = true
            isPickerPresented = true
        }
        .task(id: selectedItems) {
            guard selectedItems.isEmpty == false, hasCompletedFlow == false else {
                return
            }

            hasCompletedFlow = true
            isImporting = true

            let importedFiles = await PhotoLibraryImportService.importItems(selectedItems)

            isImporting = false
            onCompletion(importedFiles)
        }
        .task(id: isPickerPresented) {
            guard
                hasPresentedPicker,
                isPickerPresented == false,
                selectedItems.isEmpty,
                hasCompletedFlow == false
            else {
                return
            }

            hasCompletedFlow = true
            onCancel()
        }
        .modifier(PhotoLibraryPickerPresentationModifier(
            isPickerPresented: $isPickerPresented,
            selectedItems: $selectedItems
        ))
    }
}

private struct PhotoLibraryPickerPresentationModifier: ViewModifier {
    @Binding var isPickerPresented: Bool
    @Binding var selectedItems: [PhotosPickerItem]

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.photosPicker(
                isPresented: $isPickerPresented,
                selection: $selectedItems,
                maxSelectionCount: nil,
                selectionBehavior: .default,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current
            )
        } else {
            content.photosPicker(
                isPresented: $isPickerPresented,
                selection: $selectedItems,
                maxSelectionCount: nil,
                selectionBehavior: .default,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current
            )
        }
    }
}
