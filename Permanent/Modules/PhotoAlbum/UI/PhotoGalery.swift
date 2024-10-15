//
//  PhotoGalery.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 18.10.2023.

import SwiftUI
import Photos

struct PhotoGalery: View {
    
    @EnvironmentObject var service: FetchAlbumsViewModel
    
    var body: some View {
        CustomNavigationView {
            VStack {
                libraryView
                    .onAppear {
                        service.fetchAssets()
                    }
            }
            .padding()
        }
    }
    
    var libraryView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: .init(.adaptive(minimum: 60), spacing: 1),
                    count: 4
                ),
                spacing: 1
            ) {
                ForEach(service.assets, id: \.asset.localIdentifier) { fetchedAsset in
                    Button {
                        // TODO: Add tapping action here
                    } label: {
                        PhotoThumbnailView(fetchedAsset: fetchedAsset)
                    }
                }
            }.id(service.id)
        }
    }
}

#Preview {
    PhotoGalery()
}
