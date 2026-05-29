//
//  UploadActivityLiveActivity.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 22.04.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct UploadActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UploadActivityAttributes.self) { context in
            // LOCK SCREEN / BANNER VIEW
            lockScreenView(context: context)
                .widgetURL(folderURL(for: context))
        } dynamicIsland: { context in
            let status = effectiveStatus(context)
            let progressTint: Color = (status == .paused ? .orange : .blue)
            let deepLink = folderURL(for: context)
            return DynamicIsland {
                // EXPANDED DYNAMIC ISLAND — wrap each region in a Link so taps
                // anywhere in the expanded presentation open the upload folder
                // (the outer .widgetURL only covers compact + minimal).
                DynamicIslandExpandedRegion(.leading) {
                    Link(destination: deepLink) {
                        Image(systemName: expandedIcon(for: status))
                            .foregroundColor(expandedIconColor(for: status))
                            .font(.title2)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Link(destination: deepLink) {
                        expandedCenterView(context: context)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Link(destination: deepLink) {
                        Text("\(context.state.completedCount)/\(context.state.totalFiles)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if status == .uploading || status == .paused || status == .processing {
                        Link(destination: deepLink) {
                            ProgressView(value: context.state.overallProgress)
                                .tint(progressTint)
                        }
                    }
                }
            } compactLeading: {
                // COMPACT LEADING — icon
                Image(systemName: compactIcon(for: status))
                    .foregroundColor(compactIconColor(for: status))
            } compactTrailing: {
                // COMPACT TRAILING — percentage or status
                compactTrailingView(context: context)
            } minimal: {
                // MINIMAL — when competing with other Live Activities
                Image(systemName: compactIcon(for: status))
                    .foregroundColor(compactIconColor(for: status))
            }
            .widgetURL(deepLink)
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        switch context.state.status {
        case .uploading:
            if context.isStale {
                backgroundUploadingLockScreenView(context: context)
            } else {
                uploadingLockScreenView(context: context)
            }
        case .paused:
            backgroundUploadingLockScreenView(context: context)
        case .processing:
            processingLockScreenView(context: context)
        case .completed:
            completedLockScreenView(context: context)
        case .failed:
            failedLockScreenView(context: context)
        }
    }

    @ViewBuilder
    private func backgroundUploadingLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload Paused")
                        .font(.headline)
                    Text("\(context.state.completedCount) of \(context.state.totalFiles) uploaded — tap to resume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Spacer()
            }

            ProgressView(value: context.state.overallProgress)
                .tint(.orange)
        }
        .padding()
    }

    @ViewBuilder
    private func uploadingLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Uploading to Permanent")
                    .font(.headline)
                Spacer()
                Text("\(context.state.completedCount) of \(context.state.totalFiles)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            HStack {
                Text(context.state.currentFileName)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(context.state.overallProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            ProgressView(value: context.state.overallProgress)
                .tint(.blue)
        }
        .padding()
    }

    @ViewBuilder
    private func processingLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gearshape.circle.fill")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Processing Uploaded Files")
                    .font(.headline)
                Spacer()
                Text("\(Int(context.state.overallProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            Text("Processing \(context.state.completedCount) uploaded file\(context.state.completedCount == 1 ? "" : "s")…")
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: context.state.overallProgress)
                .tint(.blue)
        }
        .padding()
    }

    @ViewBuilder
    private func completedLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Upload Complete")
                    .font(.headline)
                Text("\(context.state.completedCount) file\(context.state.completedCount == 1 ? "" : "s") uploaded successfully")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func failedLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Upload Issues")
                    .font(.headline)
                if context.state.completedCount > 0 {
                    Text("\(context.state.completedCount) uploaded, \(context.state.failedCount) failed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(context.state.failedCount) file\(context.state.failedCount == 1 ? "" : "s") failed to upload")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Dynamic Island Expanded Center

    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        switch effectiveStatus(context) {
        case .uploading:
            VStack(alignment: .leading, spacing: 4) {
                Text("Uploading to Permanent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(context.state.currentFileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        case .paused:
            VStack(alignment: .leading, spacing: 4) {
                Text("Upload Paused")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(context.state.completedCount)/\(context.state.totalFiles) — tap to resume")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .processing:
            VStack(alignment: .leading, spacing: 4) {
                Text("Processing uploaded files…")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(context.state.completedCount) file\(context.state.completedCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .completed:
            Text("Upload Complete")
                .font(.caption)
                .fontWeight(.medium)
        case .failed:
            Text("\(context.state.failedCount) file\(context.state.failedCount == 1 ? "" : "s") failed")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
    }

    // MARK: - Compact Trailing

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        switch effectiveStatus(context) {
        case .uploading:
            Text("\(Int(context.state.overallProgress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        case .paused:
            Text("\(Int(context.state.overallProgress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        case .processing:
            Text("\(Int(context.state.overallProgress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        case .completed:
            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption2)
        case .failed:
            Image(systemName: "exclamationmark")
                .foregroundColor(.orange)
                .font(.caption2)
        }
    }

    // MARK: - Helpers

    /// Treat a stale `.uploading` activity as `.paused` for visual purposes,
    /// so Dynamic Island icons match the Lock Screen's orange paused state.
    private func effectiveStatus(_ context: ActivityViewContext<UploadActivityAttributes>) -> UploadActivityAttributes.UploadStatus {
        if context.state.status == .uploading && context.isStale {
            return .paused
        }
        return context.state.status
    }

    private func expandedIcon(for status: UploadActivityAttributes.UploadStatus) -> String {
        switch status {
        case .uploading: return "arrow.up.circle.fill"
        case .paused: return "pause.circle.fill"
        case .processing: return "gearshape.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private func expandedIconColor(for status: UploadActivityAttributes.UploadStatus) -> Color {
        switch status {
        case .uploading: return .blue
        case .paused: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .orange
        }
    }

    private func compactIcon(for status: UploadActivityAttributes.UploadStatus) -> String {
        switch status {
        case .uploading: return "arrow.up.circle.fill"
        case .paused: return "pause.circle.fill"
        case .processing: return "gearshape.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private func compactIconColor(for status: UploadActivityAttributes.UploadStatus) -> Color {
        switch status {
        case .uploading: return .blue
        case .paused: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .orange
        }
    }

    private func folderURL(for context: ActivityViewContext<UploadActivityAttributes>) -> URL {
        var components = URLComponents()
        components.scheme = "permanent"
        components.host = "upload-folder"
        components.queryItems = [
            URLQueryItem(name: "archiveNo", value: context.attributes.archiveNo),
            URLQueryItem(name: "folderLinkId", value: String(context.attributes.folderLinkId))
        ]
        return components.url ?? URL(string: "permanent://")!
    }
}
