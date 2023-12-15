//
//  PhotoDetailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.12.2023.

import SwiftUI

struct PhotoDetailView: View {
    @EnvironmentObject var service: FetchAlbumsViewModel
    
    @State private var image: Image?
    @State private var loadImageTask: Task<Void, Never>?
    
    private var assetLocalId: String
    
    init(assetLocalId: String) {
        self.assetLocalId = assetLocalId
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let _ = image {
                photoView
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadImageTask = Task {
                await loadImageAsset()
            }
        }
        .onDisappear {
            image = nil
        }
    }
    
    var photoView: some View {
        GeometryReader { proxy in
            image?
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: proxy.size.width)
                .frame(maxHeight: .infinity)
        }
    }
    
    func loadImageAsset() async {
        guard let uiImage = try? await service.fetchImage(
            byLocalIdentifier: assetLocalId
        ) else {
            image = nil
            return
        }
        image = uiImage
    }
}
