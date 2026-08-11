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
            // LOCK SCREEN / BANNER — 26269:50826
            UploadLockScreenBanner(display: display(for: context))
                .modifier(BannerBackground())
                .widgetURL(folderURL(for: context))
                .activitySystemActionForegroundColor(UploadActivityStyle.primaryLabel)
        } dynamicIsland: { context in
            let model = display(for: context)
            let deepLink = folderURL(for: context)
            return DynamicIsland {
                // EXPANDED — the whole design is a full-width block, and `.bottom`
                // is the only region that spans the island's full width (leading,
                // center and trailing share the row the sensor housing sits in).
                // Wrapped in a Link because the outer .widgetURL only covers the
                // compact and minimal presentations.
                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: deepLink) {
                        if model.showsFolderCard {
                            UploadExpandedCard(display: model)
                        } else {
                            UploadPillRow(display: model)
                        }
                    }
                }
            } compactLeading: {
                // COMPACT LEADING — 26268:46381, the brand mark
                BrandMark(height: UploadActivityStyle.Compact.markHeight)
            } compactTrailing: {
                // COMPACT TRAILING — 26268:46387, the progress ring. The glyph matters most
                // here: collapsed, the arc is the only signal, and a paused arc is
                // indistinguishable from a running one.
                UploadProgressRing(
                    progress: model.progress,
                    metrics: .compact,
                    tint: model.ringTint,
                    glyph: model.ringGlyph
                )
            } minimal: {
                UploadProgressRing(
                    progress: model.progress,
                    metrics: .compact,
                    tint: model.ringTint,
                    glyph: model.ringGlyph
                )
            }
            .widgetURL(deepLink)
        }
    }

    // MARK: - Display model

    /// Resolves the activity's state into the strings and accents the design calls
    /// for. Every presentation reads from this, so the Lock Screen and the Dynamic
    /// Island can't drift apart.
    private func display(for context: ActivityViewContext<UploadActivityAttributes>) -> UploadActivityDisplay {
        let state = context.state
        let status = effectiveStatus(context)
        let progress = min(max(state.overallProgress, 0), 1)
        let percentText = "\(Int(progress * 100))%"
        let counter = "\(state.completedCount) of \(state.totalFiles)"

        let headerTitle: String
        let fileLine: String
        let fileDetail: String
        let statusWord: String
        // SF Symbol naming the state inside the ring, and a hint when there is something
        // to do. Both nil while uploading: the moving arc says it, and there is no action.
        var ringGlyph: String?
        var hint: String?

        switch status {
        case .uploading:
            headerTitle = "Uploading to Permanent"
            fileLine = state.currentFileName
            fileDetail = percentText
            statusWord = "Uploading"
        case .paused:
            headerTitle = "Upload Paused"
            fileLine = "Tap to resume"
            fileDetail = percentText
            statusWord = "Paused"
            ringGlyph = "pause.fill"
            hint = "Tap to resume"
        case .processing:
            headerTitle = "Processing Uploaded Files"
            fileLine = "Finishing up…"
            fileDetail = percentText
            statusWord = "Processing"
        case .completed:
            headerTitle = "Upload Complete"
            fileLine = "\(state.completedCount) file\(state.completedCount == 1 ? "" : "s") uploaded"
            fileDetail = percentText
            statusWord = "Complete"
            ringGlyph = "checkmark"
        case .failed:
            headerTitle = "Upload Issues"
            fileLine = state.completedCount > 0
                ? "\(state.completedCount) uploaded, \(state.failedCount) failed"
                : "\(state.failedCount) file\(state.failedCount == 1 ? "" : "s") failed to upload"
            // Progress reads 100% once the batch ends, which would be misleading
            // next to a failure, so the count replaces it here.
            fileDetail = "\(state.failedCount) failed"
            statusWord = "Failed"
            ringGlyph = "exclamationmark"
        }

        return UploadActivityDisplay(
            headerTitle: headerTitle,
            counter: counter,
            fileLine: fileLine,
            fileDetail: fileDetail,
            statusWord: statusWord,
            pillDetail: " • \(counter)",
            progress: progress,
            folderName: context.attributes.folderName,
            folderItemCount: state.folderItemCount,
            folderIsShared: context.attributes.folderIsShared,
            barFill: UploadActivityStyle.progressFill(for: status),
            ringTint: UploadActivityStyle.ringTint(for: status),
            ringGlyph: ringGlyph,
            hint: hint,
            // Only the uploading state gets the folder card; the design's
            // minimum-height pill covers the rest. Overridable in DEBUG so either
            // layout can be inspected on device — see `expandedLayoutOverride`.
            showsFolderCard: UploadActivityStyle.expandedLayout(for: status) == .folderCard
        )
    }

    // MARK: - Helpers

    /// Treat a stale `.uploading` activity as `.paused` for visual purposes, so
    /// Dynamic Island accents match the Lock Screen's paused state.
    private func effectiveStatus(_ context: ActivityViewContext<UploadActivityAttributes>) -> UploadActivityAttributes.UploadStatus {
        if context.state.status == .uploading && context.isStale {
            return .paused
        }
        return context.state.status
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
