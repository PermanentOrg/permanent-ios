//
//  PhotoLibraryImportService.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14/08/2025.
//

import CoreTransferable
import Foundation
import OSLog
import PhotosUI
import SwiftUI

enum PhotoLibraryImportService {
    private static let logger = Logger(subsystem: "com.permanent.ios", category: "PhotoLibraryImport")
    private static let maximumConcurrentImports = 3

    static func importItems(_ items: [PhotosPickerItem]) async -> [SelectedUploadFile] {
        guard items.isEmpty == false else {
            return []
        }

        return await withTaskGroup(of: (Int, SelectedUploadFile?).self, returning: [SelectedUploadFile].self) { group in
            var iterator = Array(items.enumerated()).makeIterator()
            var importedFiles = Array<SelectedUploadFile?>(repeating: nil, count: items.count)

            for _ in 0..<min(maximumConcurrentImports, items.count) {
                guard let (index, item) = iterator.next() else {
                    break
                }

                group.addTask {
                    (index, await importItem(item))
                }
            }

            while let (index, selectedFile) = await group.next() {
                importedFiles[index] = selectedFile

                if let (nextIndex, nextItem) = iterator.next() {
                    group.addTask {
                        (nextIndex, await importItem(nextItem))
                    }
                }
            }

            return importedFiles.compactMap(\.self)
        }
    }

    private static func importItem(_ item: PhotosPickerItem) async -> SelectedUploadFile? {
        do {
            return try await item.loadTransferable(type: ImportedPhotoLibraryFile.self)?.selectedUploadFile
        } catch is CancellationError {
            logger.debug("Photo library import cancelled")
            return nil
        } catch {
            logger.error("Failed to import selected photo library item: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

private struct ImportedPhotoLibraryFile: Transferable {
    let selectedUploadFile: SelectedUploadFile

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try importFile(from: received)
        }

        FileRepresentation(importedContentType: .movie) { received in
            try importFile(from: received)
        }
    }

    private static func importFile(from received: ReceivedTransferredFile) throws -> ImportedPhotoLibraryFile {
        let sourceURL = received.file
        let originalFilename = sourceURL.lastPathComponent.isEmpty ? UUID().uuidString : sourceURL.lastPathComponent

        // Keep the staged file path unique while preserving the original upload filename.
        let stagedFilename = "\(UUID().uuidString)-\(originalFilename)"
        let stagedURL = try FileHelper().copyFile(withURL: sourceURL, name: stagedFilename)

        return ImportedPhotoLibraryFile(
            selectedUploadFile: SelectedUploadFile(url: stagedURL, originalFilename: originalFilename)
        )
    }
}
