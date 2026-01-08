//
//  EnhancedFileListView.swift
//  Permanent
//
//  Created for UIKit-to-SwiftUI Migration - Phase 2
//  Production-ready file list with sections, grid/list toggle, and selection support
//  Updated 18.12.2025 - Phase 3: Added folder tap navigation callback
//

import SwiftUI
import SDWebImageSwiftUI
import Combine

// MARK: - File List Section Enum

enum FileListSection: String, Hashable, CaseIterable {
    case downloading = "Downloading"
    case uploading = "Uploading"
    case files = "Files"
    
    var icon: String {
        switch self {
        case .downloading: return "arrow.down.circle.fill"
        case .uploading: return "arrow.up.circle.fill"
        case .files: return "folder.fill"
        }
    }
}

// MARK: - Enhanced File List Coordinator Protocol

protocol EnhancedFileListCoordinatorProtocol: AnyObject {
    func didTapFile(_ file: FileModel)
    func didTapMoreForFile(_ file: FileModel)
    func didLongPressFile(_ file: FileModel)
    func didCancelUpload(_ fileInfo: FileInfo)
    func didCancelDownload(_ file: FileModel)
    func didRefresh() async
}

// MARK: - Enhanced File List View

@available(iOS 17, *)
struct EnhancedFileListView: View {
    @ObservedObject var state: MainViewState
    weak var coordinator: EnhancedFileListCoordinatorProtocol?
    
    /// Callback for folder tap navigation (Phase 3 Navigation Migration)
    var onFolderTap: ((FileModel) -> Void)?
    
    // Upload progress tracking
    @State private var uploadProgress: [String: Double] = [:]
    
    var body: some View {
        Group {
            if state.isEmpty && !state.isLoading {
                emptyStateView
            } else {
                contentView
            }
        }
        .refreshable {
            await coordinator?.didRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UploadOperation.uploadProgressNotification)) { notification in
            handleUploadProgress(notification)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(Color(UIColor.lightGray))
            Text("No files")
                .font(.custom("Usual-Regular", size: 17))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Downloading Section
                if !state.downloadingFiles.isEmpty {
                    downloadingSection
                }
                
                // Uploading Section
                if !state.uploadingFiles.isEmpty {
                    uploadingSection
                }
                
                // Files Section (Grid or List)
                filesSection
            }
        }
    }
    
    // MARK: - Downloading Section
    
    private var downloadingSection: some View {
        Section {
            ForEach(state.downloadingFiles, id: \.folderLinkId) { file in
                DownloadingFileRow(
                    file: file,
                    onCancel: {
                        coordinator?.didCancelDownload(file)
                    }
                )
                .padding(.horizontal, 6)
                
                if file.folderLinkId != state.downloadingFiles.last?.folderLinkId {
                    Divider()
                        .padding(.leading, 78)
                }
            }
        } header: {
            sectionHeader(for: .downloading, count: state.downloadingFiles.count)
        }
    }
    
    // MARK: - Uploading Section
    
    private var uploadingSection: some View {
        Section {
            ForEach(state.uploadingFiles, id: \.id) { fileInfo in
                UploadingFileRow(
                    fileInfo: fileInfo,
                    progress: uploadProgress[fileInfo.id] ?? 0,
                    onCancel: {
                        coordinator?.didCancelUpload(fileInfo)
                    }
                )
                .padding(.horizontal, 6)
                
                if fileInfo.id != state.uploadingFiles.last?.id {
                    Divider()
                        .padding(.leading, 78)
                }
            }
        } header: {
            sectionHeader(for: .uploading, count: state.uploadingFiles.count)
        }
    }
    
    // MARK: - Files Section
    
    private var filesSection: some View {
        Section {
            if state.isGridView {
                gridContent
            } else {
                listContent
            }
        } header: {
            if !state.files.isEmpty {
                filesSectionHeader
            }
        }
    }
    
    private var filesSectionHeader: some View {
        HStack {
            Text(state.sortOption.title)
                .font(.custom("Usual-Medium", size: 13))
                .foregroundColor(Color(UIColor.darkBlue))
            
            Spacer()
            
            // Select All checkbox when in selection mode
            if state.isSelecting {
                selectAllButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private var selectAllButton: some View {
        Button(action: {
            if state.checkboxState == .selected {
                state.clearSelection()
            } else {
                state.selectAllFiles()
            }
        }) {
            HStack(spacing: 6) {
                Text(state.checkboxState == .selected ? "Deselect All" : "Select All")
                    .font(.custom("Usual-Regular", size: 13))
                    .foregroundColor(Color(UIColor.darkBlue))
                
                checkboxImage(for: state.checkboxState)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func checkboxImage(for state: CheckboxState) -> some View {
        switch state {
        case .none:
            Image("emptyCheckbox")
                .renderingMode(.template)
                .foregroundColor(Color(UIColor.lightGray))
        case .partial:
            Image(systemName: "minus.square.fill")
                .foregroundColor(Color(UIColor.darkBlue))
        case .selected:
            Image("fullCheckbox")
                .renderingMode(.template)
                .foregroundColor(Color(UIColor.darkBlue))
        }
    }
    
    // MARK: - Grid Content
    
    private var gridContent: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(state.files, id: \.folderLinkId) { file in
                EnhancedFileGridCell(
                    file: file,
                    isSelected: state.selectedFiles.contains(file.folderLinkId),
                    isSelectionMode: state.isSelecting,
                    onTap: {
                        handleFileTap(file)
                    },
                    onMoreTap: {
                        coordinator?.didTapMoreForFile(file)
                    },
                    onLongPress: {
                        coordinator?.didLongPressFile(file)
                    }
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(state.files, id: \.folderLinkId) { file in
                EnhancedFileListCell(
                    file: file,
                    isSelected: state.selectedFiles.contains(file.folderLinkId),
                    isSelectionMode: state.isSelecting,
                    onTap: {
                        handleFileTap(file)
                    },
                    onMoreTap: {
                        coordinator?.didTapMoreForFile(file)
                    },
                    onLongPress: {
                        coordinator?.didLongPressFile(file)
                    }
                )
                .padding(.horizontal, 6)
                
                if file.folderLinkId != state.files.last?.folderLinkId {
                    Divider()
                        .padding(.leading, 78)
                }
            }
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(for section: FileListSection, count: Int) -> some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundColor(Color(UIColor.darkBlue))
                .font(.system(size: 14))
            
            Text(section.rawValue)
                .font(.custom("Usual-Medium", size: 13))
                .foregroundColor(Color(UIColor.darkBlue))
            
            Spacer()
            
            Text("\(count)")
                .font(.custom("Usual-Regular", size: 13))
                .foregroundColor(Color(UIColor.gray))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
    }
    
    // MARK: - Actions
    
    private func handleFileTap(_ file: FileModel) {
        if state.isSelecting {
            state.toggleFileSelection(file)
        } else if file.type.isFolder {
            // Handle folder navigation (Phase 3)
            onFolderTap?(file)
        } else {
            coordinator?.didTapFile(file)
        }
    }
    
    private func handleUploadProgress(_ notification: Notification) {
        guard let operation = notification.object as? UploadOperation,
              let progressValue = notification.userInfo?["progress"] as? Double else { return }
        
        uploadProgress[operation.file.id] = progressValue
    }
}

// MARK: - Uploading File Row

struct UploadingFileRow: View {
    let fileInfo: FileInfo
    let progress: Double
    let onCancel: () -> Void
    
    private var isWaiting: Bool {
        progress == 0
    }
    
    private var isFailed: Bool {
        fileInfo.didFailUpload
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            fileIconView
                .frame(width: 60, height: 60)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(fileInfo.name)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isFailed ? .red : Color(UIColor.black))
                    .lineLimit(2)
                
                if isFailed {
                    Text("Upload failed")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                } else if isWaiting {
                    Text("Waiting...")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.gray))
                } else {
                    HStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.darkBlue))
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.darkBlue)))
                            .frame(maxWidth: 100)
                    }
                }
            }
            
            Spacer()
            
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.lightGray))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var fileIconView: some View {
        let iconName = iconForMimeType(fileInfo.mimeType)
        
        ZStack {
            Color(UIColor.systemGray6)
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(Color(UIColor.darkBlue))
        }
    }
    
    private func iconForMimeType(_ mimeType: String?) -> String {
        guard let mime = mimeType?.lowercased() else { return "doc" }
        
        if mime.hasPrefix("image/") { return "photo" }
        if mime.hasPrefix("video/") { return "video.fill" }
        if mime.hasPrefix("audio/") { return "music.note" }
        if mime.contains("pdf") { return "doc.text.fill" }
        return "doc"
    }
}

// MARK: - Downloading File Row

struct DownloadingFileRow: View {
    let file: FileModel
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(UIColor.black))
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text("Downloading...")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.orange))
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.orange)))
                        .scaleEffect(0.7)
                }
            }
            
            Spacer()
            
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.lightGray))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = file.thumbnailURL2000 ?? file.thumbnailURL {
            WebImage(url: URL(string: thumbnailURL))
                .resizable()
                .placeholder {
                    ZStack {
                        Color(UIColor.systemGray6)
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                .indicator(.activity)
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                Color(UIColor.systemGray6)
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
    
    private var iconName: String {
        if file.type.isFolder { return "folder.fill" }
        switch file.type {
        case .image: return "photo"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .pdf: return "doc.text.fill"
        default: return "doc"
        }
    }
}

// MARK: - Enhanced File List Cell

struct EnhancedFileListCell: View {
    let file: FileModel
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onMoreTap: () -> Void
    let onLongPress: () -> Void
    
    private var canShowMore: Bool {
        file.permissions.contains(.delete) || file.permissions.contains(.edit)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(file.name)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color(UIColor.darkBlue) : Color(UIColor.black))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Selection checkbox or more button
                    rightButton
                }
                
                HStack(spacing: 8) {
                    Text(file.date)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.gray))
                    
                    if !file.type.isFolder && file.size > 0 {
                        Text("•")
                            .foregroundColor(Color(UIColor.lightGray))
                        Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.gray))
                    }
                    
                    if !file.minArchiveVOS.isEmpty {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.darkBlue))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color(UIColor.darkBlue).opacity(0.1) : Color(UIColor.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = file.thumbnailURL2000 ?? file.thumbnailURL {
            WebImage(url: URL(string: thumbnailURL))
                .resizable()
                .placeholder {
                    ZStack {
                        Color(UIColor.systemGray6)
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                .indicator(.activity)
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                Color(UIColor.systemGray6)
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
    
    @ViewBuilder
    private var rightButton: some View {
        if isSelectionMode {
            Image(isSelected ? "fullCheckbox" : "emptyCheckbox")
                .renderingMode(.template)
                .foregroundColor(isSelected ? Color(UIColor.darkBlue) : Color(UIColor.lightGray))
                .frame(width: 24, height: 24)
        } else if canShowMore {
            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.darkBlue))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var iconName: String {
        if file.type.isFolder { return "folder.fill" }
        switch file.type {
        case .image: return "photo"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .pdf: return "doc.text.fill"
        default: return "doc"
        }
    }
}

// MARK: - Enhanced File Grid Cell

struct EnhancedFileGridCell: View {
    let file: FileModel
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onMoreTap: () -> Void
    let onLongPress: () -> Void
    
    private var canShowMore: Bool {
        file.permissions.contains(.delete) || file.permissions.contains(.edit)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                thumbnailView
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .cornerRadius(12)
                
                // Selection checkbox or more button overlay
                if isSelectionMode {
                    Image(isSelected ? "fullCheckbox" : "emptyCheckbox")
                        .renderingMode(.template)
                        .foregroundColor(isSelected ? Color(UIColor.darkBlue) : Color(UIColor.lightGray))
                        .frame(width: 24, height: 24)
                        .padding(8)
                } else if canShowMore {
                    Button(action: onMoreTap) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
                
                // Share indicator
                if !file.minArchiveVOS.isEmpty {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(UIColor.darkBlue))
                            .clipShape(Circle())
                            .padding(8)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(UIColor.darkBlue) : Color(UIColor.black))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(file.date)
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.gray))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(isSelected ? Color(UIColor.darkBlue).opacity(0.1) : Color(UIColor.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(UIColor.darkBlue) : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = file.thumbnailURL2000 ?? file.thumbnailURL {
            WebImage(url: URL(string: thumbnailURL))
                .resizable()
                .placeholder {
                    ZStack {
                        Color(UIColor.systemGray6)
                        Image(systemName: iconName)
                            .font(.system(size: 36))
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                .indicator(.activity)
                .scaledToFill()
        } else {
            ZStack {
                Color(UIColor.systemGray6)
                Image(systemName: iconName)
                    .font(.system(size: 36))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
    
    private var iconName: String {
        if file.type.isFolder { return "folder.fill" }
        switch file.type {
        case .image: return "photo"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .pdf: return "doc.text.fill"
        default: return "doc"
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17, *)
struct EnhancedFileListView_Previews: PreviewProvider {
    static var previews: some View {
        // Note: Preview requires a mock MainViewState
        Text("EnhancedFileListView Preview")
            .font(.headline)
    }
}
#endif
