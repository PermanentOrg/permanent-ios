//
//  FileGridItemView.swift
//  Permanent
//
//  Created by Copilot on 17/12/2025.
//

import SwiftUI
import SDWebImageSwiftUI

/// SwiftUI grid-style file cell matching UIKit FileCollectionViewCell grid layout
struct FileGridItemView: View {
    let file: FileItemViewModel
    let onMoreTap: (() -> Void)?
    let onTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                thumbnailView
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .cornerRadius(12)
                
                // Selection or more button overlay
                if file.isSelectionMode {
                    Image(file.isSelected ? "fullCheckbox" : "emptyCheckbox")
                        .renderingMode(.template)
                        .foregroundColor(file.isSelected ? Color(UIColor.darkBlue) : Color(UIColor.lightGray))
                        .frame(width: 24, height: 24)
                        .padding(8)
                } else if file.canShowMore {
                    Button(action: { onMoreTap?() }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
                
                // Share indicator
                if file.hasShares {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(UIColor.darkBlue))
                            .clipShape(Circle())
                            .padding(8)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.system(size: 14, weight: file.isSelected ? .semibold : .regular))
                    .foregroundColor(file.isSelected ? Color(UIColor.darkBlue) : Color(UIColor.black))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(file.displayDate)
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.gray))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Upload progress
            if file.fileStatus == .uploading {
                ProgressView(value: 0.5)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.darkBlue)))
                    .frame(height: 2)
            }
        }
        .padding(8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = file.thumbnailURL2000 ?? file.thumbnailURL {
            WebImage(url: URL(string: thumbnailURL))
                .resizable()
                .placeholder {
                    ZStack {
                        Color(UIColor.systemGray6)
                        Image(systemName: file.iconName)
                            .font(.system(size: 36))
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                .indicator(.activity)
                .scaledToFill()
        } else {
            ZStack {
                Color(UIColor.systemGray6)
                Image(systemName: file.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FileGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            FileGridItemView(
                file: FileItemViewModel(
                    from: FileModel(
                        name: "Family Photo.jpg",
                        recordId: 1,
                        folderLinkId: 1,
                        archiveNbr: "0000-0000",
                        type: "type.file.image",
                        permissions: [.read, .edit, .delete]
                    )
                ),
                onMoreTap: {},
                onTap: {}
            )
            
            FileGridItemView(
                file: FileItemViewModel(
                    from: FileModel(
                        name: "Documents Folder",
                        recordId: 2,
                        folderLinkId: 2,
                        archiveNbr: "0000-0000",
                        type: "type.folder.root.private",
                        permissions: [.read, .edit, .delete]
                    )
                ),
                onMoreTap: {},
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
