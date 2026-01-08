//
//  FileListView.swift
//  Permanent
//
//  Created by Copilot on 17/12/2025.
//

import SwiftUI

/// Coordinator protocol to bridge SwiftUI file list to UIKit actions
protocol FileListCoordinatorProtocol: AnyObject {
    func didTapFile(_ file: FileItemViewModel)
    func didTapMore(for file: FileItemViewModel)
    func didLongPress(_ file: FileItemViewModel)
    func didToggleSelection(_ file: FileItemViewModel)
    func didRefresh() async
}

/// SwiftUI file list view supporting both list and grid layouts
struct FileListView: View {
    @ObservedObject var viewModel: FileListViewModel
    weak var coordinator: FileListCoordinatorProtocol?
    
    var body: some View {
        Group {
            if viewModel.files.isEmpty {
                emptyStateView
            } else if viewModel.isGridView {
                gridView
            } else {
                listView
            }
        }
        .refreshable {
            await coordinator?.didRefresh()
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
    
    // MARK: - List Layout
    
    private var listView: some View {
        List {
            ForEach(viewModel.files) { file in
                FileListItemView(
                    file: file,
                    onMoreTap: {
                        coordinator?.didTapMore(for: file)
                    },
                    onTap: {
                        if viewModel.isSelectionMode {
                            coordinator?.didToggleSelection(file)
                        } else {
                            coordinator?.didTapFile(file)
                        }
                    }
                )
                .onLongPressGesture {
                    coordinator?.didLongPress(file)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Grid Layout
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(viewModel.files) { file in
                    FileGridItemView(
                        file: file,
                        onMoreTap: {
                            coordinator?.didTapMore(for: file)
                        },
                        onTap: {
                            if viewModel.isSelectionMode {
                                coordinator?.didToggleSelection(file)
                            } else {
                                coordinator?.didTapFile(file)
                            }
                        }
                    )
                    .onLongPressGesture {
                        coordinator?.didLongPress(file)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
        }
    }
}

/// View model for FileListView
class FileListViewModel: ObservableObject {
    @Published var files: [FileItemViewModel] = []
    @Published var isGridView: Bool = false
    @Published var isSelectionMode: Bool = false
    @Published var selectedFileIds: Set<Int> = []
    
    func updateFiles(_ models: [FileModel]) {
        print("📝 FileListViewModel.updateFiles called with \(models.count) files")
        files = models.map { model in
            var file = FileItemViewModel(from: model)
            file.isSelectionMode = isSelectionMode
            file.isSelected = selectedFileIds.contains(model.recordId)
            return file
        }
        print("📝 FileListViewModel.files now has \(files.count) items")
    }
    
    func toggleSelection(for fileId: Int) {
        if selectedFileIds.contains(fileId) {
            selectedFileIds.remove(fileId)
        } else {
            selectedFileIds.insert(fileId)
        }
        // Re-map files to update selection state
        files = files.map { file in
            var updatedFile = file
            updatedFile.isSelected = selectedFileIds.contains(file.id)
            return updatedFile
        }
    }
    
    func enterSelectionMode(with fileId: Int) {
        isSelectionMode = true
        selectedFileIds = [fileId]
        updateSelectionState()
    }
    
    func exitSelectionMode() {
        isSelectionMode = false
        selectedFileIds.removeAll()
        updateSelectionState()
    }
    
    private func updateSelectionState() {
        files = files.map { file in
            var updatedFile = file
            updatedFile.isSelectionMode = isSelectionMode
            updatedFile.isSelected = selectedFileIds.contains(file.id)
            return updatedFile
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FileListViewModel()
        viewModel.files = [
            FileItemViewModel(
                from: FileModel(
                    name: "Family Photo.jpg",
                    recordId: 1,
                    folderLinkId: 1,
                    archiveNbr: "0000-0000",
                    type: "type.file.image",
                    permissions: [.read, .edit, .delete]
                )
            ),
            FileItemViewModel(
                from: FileModel(
                    name: "Documents Folder",
                    recordId: 2,
                    folderLinkId: 2,
                    archiveNbr: "0000-0000",
                    type: "type.folder.root.private",
                    permissions: [.read, .edit, .delete]
                )
            )
        ]
        
        return FileListView(viewModel: viewModel, coordinator: nil)
    }
}
#endif
