//
//  PhotoThumbnailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.12.2023.

import SwiftUI
import Photos
import UIKit

struct PhotoThumbnailView: View {
    
    private var assetLocalId: String
    @State private var image: Image?
    @State private var loadImageTask: Task<Void, Never>?
    
    @EnvironmentObject var service: FetchAlbumsViewModel
    
    init(assetLocalId: String) {
        self.assetLocalId = assetLocalId
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                GeometryReader { proxy in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.width
                        )
                        .clipped()
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .aspectRatio(1, contentMode: .fit)
                ProgressView()
            }
        }
        .onAppear {
            loadImageTask = Task {
                await loadImageAsset(targetSize: CGSize(width: 150, height: 150))
            }
        }
        .onDisappear {
            image = nil
        }
    }
    
    func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = try? await service
            .fetchImage(
                byLocalIdentifier: assetLocalId,
                targetSize: targetSize
            ) else {
            image = nil
            return
        }
        image =  uiImage
    }
}
