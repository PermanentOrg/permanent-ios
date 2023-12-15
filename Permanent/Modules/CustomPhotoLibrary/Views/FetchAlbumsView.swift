//
//  FetchAlbumsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.12.2023.

import SwiftUI

struct FetchAlbumsView: View {
    @StateObject var viewModel: CustomPhotoLibraryViewModel
    @EnvironmentObject var service: FetchAlbumsViewModel
    @Binding var selectedSegment: Int
    
    var body: some View {
        VStack {
            libraryView
                .onAppear {
                    service.loadImagesForSegment(segment: selectedSegment)
                }
                .onChange(of: selectedSegment) { newValue in
                    service.loadImagesForSegment(segment: newValue)
                }
        }
    }
    
    var libraryView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: Array(
                    repeating: .init(.adaptive(minimum: 100), spacing: 1),
                    count: 3
                ),
                spacing: 1
            ) {
                ForEach(service.assets, id: \.localIdentifier) { asset in
                    Button {
                        if viewModel.selectedPhotos.contains(asset) {
                            viewModel.selectedPhotos.remove(asset)
                        } else {
                            viewModel.selectedPhotos.insert(asset)
                        }
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            PhotoThumbnailView(assetLocalId: asset.localIdentifier)
                            if viewModel.selectedPhotos.contains(asset) {
                                Image(.checkmarkSelectItem)
                                    .frame(width: 19, height: 19)
                                    .padding(5)
                            }
                        }
                    }
                }
            }
        }
    }
}
