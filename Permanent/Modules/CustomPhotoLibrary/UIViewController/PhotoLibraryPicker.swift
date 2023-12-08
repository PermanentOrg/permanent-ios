//
//  PhotoLibraryPicker.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.12.2023.

import SwiftUI
import PhotosUI

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedAssets: [PHAsset]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0  // 0 for unlimited selection
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No update needed here
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            let identifiers = results.compactMap(\.assetIdentifier)
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            DispatchQueue.main.async {
                self.parent.selectedAssets = assets.objects(at: IndexSet(0..<assets.count))
            }
        }
    }
}
