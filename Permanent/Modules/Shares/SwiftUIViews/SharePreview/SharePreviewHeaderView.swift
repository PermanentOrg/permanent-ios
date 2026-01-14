//
//  SharePreviewHeaderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI
import SDWebImageSwiftUI

struct SharePreviewHeaderView: View {
    let shareName: String
    let sharedByName: String
    let archiveName: String
    let thumbnailURL: String?
    
    var body: some View {
        HStack(spacing: 16) {
            if let urlString = thumbnailURL, let url = URL(string: urlString) {
                WebImage(url: url)
                    .resizable()
                    .placeholder {
                        // Subtle neutral placeholder to avoid a bright blue block during load
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.12))
                            .overlay(Text(extractInitials(from: sharedByName)).font(.system(size: 16, weight: .medium)).foregroundColor(.secondary))
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.15)) // smooth fade when the image appears
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.clear))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.12))
                    .overlay(Text(extractInitials(from: sharedByName)).font(.system(size: 16, weight: .medium)).foregroundColor(.secondary))
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sharedByName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(archiveName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.blue25)
    }
    
    private func extractInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return name.prefix(1).uppercased()
    }
}

struct SharePreviewHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewHeaderView(shareName: "AquaPark Party", sharedByName: "Robert Friedman", archiveName: "Family", thumbnailURL: nil)
            .previewLayout(.sizeThatFits)
    }
}
