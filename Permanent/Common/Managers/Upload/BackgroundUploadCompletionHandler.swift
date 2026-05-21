//
//  BackgroundUploadCompletionHandler.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.04.2026.
//

import Foundation
import os.log

/// Handles registerRecord calls for uploads that completed while the app was
/// terminated. When the app relaunches and reconnects to the background session,
/// this class picks up where the UploadOperation left off.
enum BackgroundUploadCompletionHandler {
    private static let logger = Logger(subsystem: "com.permanent.ios", category: "BackgroundUploadCompletion")
    private static let maxRetries = 3

    /// Called by BackgroundUploadSessionManager when an upload completed but
    /// no in-memory UploadOperation handler exists (app was relaunched).
    static func handleCompletedUpload(metadata: BackgroundUploadMetadata) {
        logger.info("Handling post-relaunch registerRecord for file: \(metadata.fileName, privacy: .public)")

        registerRecord(metadata: metadata, attempt: 1)
    }

    private static func registerRecord(metadata: BackgroundUploadMetadata, attempt: Int) {
        let params = RegisterRecordParams(
            metadata.folderId,
            metadata.folderLinkId,
            metadata.fileName,
            metadata.createdDT,
            metadata.s3Url,
            metadata.destinationUrl
        )

        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response),
                      model.isSuccessful == true else {
                    logger.error("registerRecord response unsuccessful for file: \(metadata.fileName, privacy: .public), attempt: \(attempt, privacy: .public)")
                    retryOrFail(metadata: metadata, attempt: attempt)
                    return
                }

                logger.info("Successfully registered file after relaunch: \(metadata.fileName, privacy: .public)")
                cleanup(metadata: metadata, success: true)

            case .error(let error, _):
                logger.error("registerRecord error: \(error.debugDescription, privacy: .public), attempt: \(attempt, privacy: .public)")
                retryOrFail(metadata: metadata, attempt: attempt)

            default:
                logger.error("Unexpected result from registerRecord for file: \(metadata.fileName, privacy: .public)")
                cleanup(metadata: metadata, success: false)
            }
        }
    }

    private static func retryOrFail(metadata: BackgroundUploadMetadata, attempt: Int) {
        if attempt < maxRetries {
            let delay = pow(2.0, Double(attempt)) // Exponential backoff: 2s, 4s, 8s
            logger.info("Retrying registerRecord in \(delay, privacy: .public)s (attempt \(attempt + 1, privacy: .public)/\(maxRetries, privacy: .public))")

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                registerRecord(metadata: metadata, attempt: attempt + 1)
            }
        } else {
            logger.error("All \(maxRetries, privacy: .public) registerRecord retries exhausted for file: \(metadata.fileName, privacy: .public)")
            cleanup(metadata: metadata, success: false)
        }
    }

    private static func cleanup(metadata: BackgroundUploadMetadata, success: Bool) {
        BackgroundUploadMetadata.remove(taskIdentifier: metadata.taskIdentifier)
        BackgroundUploadSessionManager.shared.cleanupTempFile(at: metadata.tempFilePath)

        DispatchQueue.main.async {
            var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)

            let fileURL = savedFiles?.first(where: { $0.id == metadata.fileInfoId })?.url
            savedFiles?.removeAll { $0.id == metadata.fileInfoId }
            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)

            if success, let fileURL = fileURL {
                FileHelper().deleteFile(at: fileURL)
            }

            UploadLiveActivityManager.shared.fileCompleted(success: success)

            NotificationCenter.default.post(name: UploadManager.didUploadFileNotification, object: nil, userInfo: nil)
        }
    }
}
