//
//  PhotoGalery.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 18.10.2023.

import SwiftUI
import Photos

struct PhotoGalery: View {
    
    @EnvironmentObject var service: FetchAlbumsViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        CustomNavigationView {
            VStack {
                libraryView
                    .onAppear {
                        service.fetchAssets()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { (_) in
                        print("did become active")
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
