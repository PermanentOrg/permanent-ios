//
//  UIViewControllerDuplicateUploadPrompt.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.05.2026.
//
//  Guard 0 UX: when the user picks files for upload and some of them already
//  exist (by `uploadFileName`) in the destination folder, present a modal
//  alert with three explicit choices. We never silently swallow re-uploads —
//  doing so would break the user's mental model — but we also don't quietly
//  let the duplicate happen unless the user asks for it.
//

import UIKit

enum DuplicateUploadChoice {
    /// Upload only the files that aren't already in the folder. The default.
    case skipDuplicates
    /// Upload everything the user picked, producing duplicates in the folder.
    /// Preserves prior behaviour for users who deliberately want a second copy.
    case uploadAll
    /// Abandon the entire batch.
    case cancel
}

extension UIViewController {
    /// Surfaces existing-in-folder files to the user before any bytes leave
    /// the device.
    ///
    /// - Parameters:
    ///   - total: total number of files the user picked.
    ///   - duplicateFileNames: filenames already present in the destination
    ///     folder. Must be a subset of the picked files; `count <= total`.
    ///   - completion: invoked with the user's choice on the main queue.
    func promptDuplicateUploadDecision(
        total: Int,
        duplicateFileNames: [String],
        completion: @escaping (DuplicateUploadChoice) -> Void
    ) {
        let duplicateCount = duplicateFileNames.count
        let allDuplicate = duplicateCount == total
        let remaining = total - duplicateCount

        // Title + summary line.
        let title: String
        let summary: String
        if allDuplicate {
            title = "These files already exist"
            summary = duplicateCount == 1
                ? "This file is already in this folder."
                : "All \(duplicateCount) files are already in this folder."
        } else {
            title = "Some files already exist"
            summary = "\(duplicateCount) of \(total) files are already in this folder."
        }

        // List the names when there are few enough to read at a glance.
        let listLimit = 5
        let names: String
        if duplicateFileNames.count <= listLimit {
            names = "\n\n" + duplicateFileNames.joined(separator: "\n")
        } else {
            names = ""
        }

        let alert = UIAlertController(
            title: title,
            message: summary + names,
            preferredStyle: .alert
        )

        // Skip duplicates — only when there's something to upload afterwards.
        if !allDuplicate {
            let skip = UIAlertAction(
                title: "Skip duplicates (upload \(remaining))",
                style: .default
            ) { _ in completion(.skipDuplicates) }
            alert.addAction(skip)
            alert.preferredAction = skip
        }

        // Upload anyway — preserves prior behaviour for intentional re-uploads.
        let uploadAllTitle: String
        if allDuplicate {
            uploadAllTitle = duplicateCount == 1 ? "Upload anyway" : "Upload all \(total) anyway"
        } else {
            uploadAllTitle = "Upload anyway"
        }
        let uploadAllAction = UIAlertAction(
            title: uploadAllTitle,
            style: .default
        ) { _ in completion(.uploadAll) }
        alert.addAction(uploadAllAction)
        if allDuplicate {
            alert.preferredAction = uploadAllAction
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(.cancel)
        })

        present(alert, animated: true)
    }
}
