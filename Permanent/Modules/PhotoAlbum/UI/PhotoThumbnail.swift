//
//  PhotoThumbnail.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 02.10.2024.

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    
//    private var assetLocalId: String
    @State private var image: Image?
    @ObservedObject var fetchedAsset: FetchedAssets
    
    @EnvironmentObject var service: FetchAlbumsViewModel
    
//    init(assetLocalId: String, isBacked: Binding<Bool>) {
//        self.assetLocalId = assetLocalId
//        _isBacked = isBacked
//    }
    
    var body: some View {
        ZStack {
            if let image = image {
                GeometryReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.width
                            )
                            .clipped()
                        if fetchedAsset.isUploaded {
                            Image(systemName: "cloud")
                                .tint(.white)
                                .padding(5)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .aspectRatio(1, contentMode: .fit)
                ProgressView()
            }
        }
        .task {
            await loadImageAsset(targetSize: CGSizeMake(60, 60))
        }
        .onDisappear {
            image = nil
        }
    }
    
    func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = try? await service
            .fetchImage(
                byLocalIdentifier: fetchedAsset.asset.localIdentifier,
                targetSize: targetSize
            ) else {
            image = nil
            return
        }
        image = Image(uiImage: uiImage)
    }
}
