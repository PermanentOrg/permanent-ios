//
//  CachedAsyncImage.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.05.2026.
//

import SwiftUI
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
        if let url, let cached = ImageCache.shared.image(for: url) {
            self._image = State(initialValue: cached)
        }
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .onAppear {
            Task { await load() }
        }
    }

    private func load() async {
        guard image == nil, let url else { return }
        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let downloaded = UIImage(data: data) else { return }
        ImageCache.shared.insert(downloaded, for: url)
        self.image = downloaded
    }
}
