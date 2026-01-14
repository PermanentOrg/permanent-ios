//
//  SharePreviewGridView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI
import SDWebImageSwiftUI

struct SharePreviewGridView: View {
    let items: [SharePreviewItem]
    let isBlurred: Bool
    
    private let lateralPadding: CGFloat = 24
    private let itemSpacing: CGFloat = 8

    private func arrangeItems(_ items: [SharePreviewItem]) -> [SharePreviewItem] {
        let folders = items.filter { $0.isFolder }
        let images = items.filter { !$0.isFolder }
        
        var arrangedItems: [SharePreviewItem] = []
        var folderIndex = 0
        var imageIndex = 0
        
        // Build arranged array following the pattern
        for slot in 0..<items.count {
            let positionInCycle = slot % 4
            
            // Positions 0 and 2 are small squares (prefer folders)
            if positionInCycle == 0 || positionInCycle == 2 {
                if folderIndex < folders.count {
                    arrangedItems.append(folders[folderIndex])
                    folderIndex += 1
                } else if imageIndex < images.count {
                    arrangedItems.append(images[imageIndex])
                    imageIndex += 1
                }
            }
            // Positions 1 and 3 are tall/full width (images only)
            else {
                if imageIndex < images.count {
                    arrangedItems.append(images[imageIndex])
                    imageIndex += 1
                } else if folderIndex < folders.count {
                    arrangedItems.append(folders[folderIndex])
                    folderIndex += 1
                }
            }
        }
        
        return arrangedItems
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let availableWidth = totalWidth - (lateralPadding * 2)
            let columnWidth = (availableWidth - itemSpacing) / 2
            let tallHeight = columnWidth * 2 + itemSpacing
            let arrangedItems = arrangeItems(items)
            
            VStack(spacing: itemSpacing) {
                // Pattern repeats every 4 items: square + tall, square, full width
                ForEach(0..<((arrangedItems.count + 3) / 4), id: \.self) { cycleIndex in
                    let baseIndex = cycleIndex * 4
                    
                    // Items 0, 1, 2: Square + Tall (2 rows), Square
                    if baseIndex < arrangedItems.count {
                        HStack(alignment: .top, spacing: itemSpacing) {
                            VStack(spacing: itemSpacing) {
                                // First square (item 0, 4, 8, etc.)
                                if arrangedItems[baseIndex].isFolder {
                                    FolderItemView(item: arrangedItems[baseIndex], width: columnWidth, isBlurred: isBlurred)
                                } else {
                                    ImageItemView(item: arrangedItems[baseIndex], width: columnWidth, height: columnWidth, isBlurred: isBlurred)
                                }
                                
                                // Second square below (item 2, 6, 10, etc.)
                                if baseIndex + 2 < arrangedItems.count {
                                    if arrangedItems[baseIndex + 2].isFolder {
                                        FolderItemView(item: arrangedItems[baseIndex + 2], width: columnWidth, isBlurred: isBlurred)
                                    } else {
                                        ImageItemView(item: arrangedItems[baseIndex + 2], width: columnWidth, height: columnWidth, isBlurred: isBlurred)
                                    }
                                }
                            }
                            
                            // Tall image on right (item 1, 5, 9, etc.)
                            if baseIndex + 1 < arrangedItems.count {
                                if arrangedItems[baseIndex + 1].isFolder {
                                    FolderItemView(item: arrangedItems[baseIndex + 1], width: columnWidth, isBlurred: isBlurred)
                                } else {
                                    ImageItemView(item: arrangedItems[baseIndex + 1], width: columnWidth, height: tallHeight, isBlurred: isBlurred)
                                }
                            }
                        }
                    }
                    
                    // Item 3: Full width (item 3, 7, 11, etc.)
                    if baseIndex + 3 < arrangedItems.count {
                        if arrangedItems[baseIndex + 3].isFolder {
                            FolderItemView(item: arrangedItems[baseIndex + 3], width: availableWidth, isBlurred: isBlurred)
                        } else {
                            ImageItemView(item: arrangedItems[baseIndex + 3], width: availableWidth, height: availableWidth, isBlurred: isBlurred)
                        }
                    }
                }
            }
            .padding(.horizontal, lateralPadding)
            .padding(.top, 8)
        }
    }
}

struct FolderItemView: View {
    let item: SharePreviewItem
    let width: CGFloat
    let isBlurred: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
                Image("sharePreviewFolder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 62)
                    .blur(radius: isBlurred ? 10 : 0)
                
                Text(item.name)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .center)
                    .padding(.leading, 4)
                    .blur(radius: isBlurred ? 10 : 0)
        }
        .padding(.vertical, 16)
        .frame(width: width, height: width)
        .cornerRadius(12)
    }
}

struct ImageItemView: View {
    let item: SharePreviewItem
    let width: CGFloat
    let height: CGFloat
    let isBlurred: Bool

    var body: some View {
        if isBlurred, let placeholderImageName = item.placeholderImageName {
            // Show placeholder image
            Image(placeholderImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(12)
                .blur(radius: 10)
        } else if let urlString = item.thumbnailURL, let url = URL(string: urlString) {
            WebImage(url: url)
                .resizable()
                .placeholder {
                    Rectangle().fill(Color.gray.opacity(0.2)).overlay(ProgressView())
                }
                .indicator(.activity)
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(12)
                .blur(radius: isBlurred ? 10 : 0)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
                .cornerRadius(12)
                .blur(radius: isBlurred ? 10 : 0)
        }
    }
}

struct SharePreviewGridView_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewGridView(items: [
            SharePreviewItem(id: "ph1", name: "Winter", thumbnailURL: nil, isFolder: true, type: .folder, placeholderImageName: "sharePreviewFolder"),
            SharePreviewItem(id: "ph2", name: "Photo", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageOne"),
            SharePreviewItem(id: "ph3", name: "Image", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageTwo"),
            SharePreviewItem(id: "ph4", name: "Picture", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageThree"),
            SharePreviewItem(id: "ph6", name: "Photo", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageOne"),
            SharePreviewItem(id: "ph5", name: "Summer", thumbnailURL: nil, isFolder: true, type: .folder, placeholderImageName: "sharePreviewFolder"),
            SharePreviewItem(id: "ph7", name: "Image", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageTwo"),
            SharePreviewItem(id: "ph8", name: "Picture", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageThree")
        ], isBlurred: true)
    }
}
