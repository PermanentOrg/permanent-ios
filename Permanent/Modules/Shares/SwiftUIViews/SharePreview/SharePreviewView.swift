//
//  SharePreviewView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI

struct SharePreviewView: View {
    @StateObject private var viewModel: SharePreviewSwiftUIViewModel
    
    init(shareToken: String,
         onNavigateToFolder: ((NavigateMinParams) -> Void)? = nil,
         onNavigateToShares: ((String) -> Void)? = nil) {
        let vm = SharePreviewSwiftUIViewModel(shareToken: shareToken)
        vm.onNavigateToFolder = onNavigateToFolder
        vm.onNavigateToShares = onNavigateToShares
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.blue25.ignoresSafeArea()
            
            VStack(spacing: 0) {
                SharePreviewHeaderView(
                    shareName: viewModel.shareName,
                    sharedByName: viewModel.sharedByName,
                    archiveName: viewModel.archiveName,
                    thumbnailURL: viewModel.thumbnailURL
                )
                
                ZStack(alignment: .bottom) {
                    ScrollView {
                        SharePreviewGridView(
                            items: viewModel.items,
                            isBlurred: viewModel.displayMode == .blurredPlaceholders
                        )
                            .padding(.top, 16)
                            .padding(.bottom, 200)
                    }
                    .disabled(viewModel.displayMode == .blurredPlaceholders)
                    
                    SharePreviewArchiveSelectorView(
                        currentArchive: viewModel.currentArchive,
                        availableArchives: viewModel.availableArchives,
                        onSelect: { archive in viewModel.selectArchive(archive) },
                        onViewInArchive: { viewModel.viewInArchive() }
                    )
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().progressViewStyle(CircularProgressViewStyle()).scaleEffect(1.2)
            }
        }
        .navigationTitle(viewModel.shareName.isEmpty ? "Share Preview" : viewModel.shareName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.cancelLoadingTask() }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("OK"), action: { viewModel.errorMessage = nil }))
        }
    }
}

struct SharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SharePreviewView(shareToken: "mock")
        }
    }
}
