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
            DynamicIsland {
                // EXPANDED DYNAMIC ISLAND
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: expandedIcon(for: context.state.status))
                        .foregroundColor(expandedIconColor(for: context.state.status))
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedCount)/\(context.state.totalFiles)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.status == .uploading || context.state.status == .paused {
                        ProgressView(value: context.state.overallProgress)
                            .tint(context.state.status == .paused ? .gray : .blue)
                    }
                }
            } compactLeading: {
                // COMPACT LEADING — icon
                Image(systemName: compactIcon(for: context.state.status))
                    .foregroundColor(compactIconColor(for: context.state.status))
            } compactTrailing: {
                // COMPACT TRAILING — percentage or status
                compactTrailingView(context: context)
            } minimal: {
                // MINIMAL — when competing with other Live Activities
                Image(systemName: compactIcon(for: context.state.status))
                    .foregroundColor(compactIconColor(for: context.state.status))
            }
            .widgetURL(folderURL(for: context))
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        switch context.state.status {
        case .uploading:
            if context.isStale {
                interruptedLockScreenView(context: context)
            } else {
                uploadingLockScreenView(context: context)
            }
        case .paused:
            interruptedLockScreenView(context: context)
        case .completed:
            completedLockScreenView(context: context)
        case .failed:
            failedLockScreenView(context: context)
        }
    }

    @ViewBuilder
    private func interruptedLockScreenView(context: ActivityViewContext<UploadActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.gray)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Upload Interrupted")
                    .font(.headline)
                Text("Open the app to resume uploading")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
        switch context.state.status {
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
                Text("Open app to resume")
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
        switch context.state.status {
        case .uploading:
            Text("\(Int(context.state.overallProgress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
        case .paused:
            Text("Paused")
                .font(.caption2)
                .foregroundColor(.gray)
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

    private func expandedIcon(for status: UploadActivityAttributes.UploadStatus) -> String {
        switch status {
        case .uploading: return "arrow.up.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private func expandedIconColor(for status: UploadActivityAttributes.UploadStatus) -> Color {
        switch status {
        case .uploading: return .blue
        case .paused: return .gray
        case .completed: return .green
        case .failed: return .orange
        }
    }

    private func compactIcon(for status: UploadActivityAttributes.UploadStatus) -> String {
        switch status {
        case .uploading: return "arrow.up.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private func compactIconColor(for status: UploadActivityAttributes.UploadStatus) -> Color {
        switch status {
        case .uploading: return .blue
        case .paused: return .gray
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
