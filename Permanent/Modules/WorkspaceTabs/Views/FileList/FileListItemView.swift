//
//  FileListItemView.swift
//  Permanent
//
//  Created by Copilot on 17/12/2025.
//

import SwiftUI
import SDWebImageSwiftUI

/// SwiftUI list-style file cell matching UIKit FileCollectionViewCell
struct FileListItemView: View {
    let file: FileItemViewModel
    let onMoreTap: (() -> Void)?
    let onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            thumbnailView
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(file.displayName)
                        .font(.system(size: 16, weight: file.isSelected ? .semibold : .regular))
                        .foregroundColor(file.isSelected ? Color(UIColor.darkBlue) : Color(UIColor.black))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Selection or more button
                    rightButton
                }
                
                HStack(spacing: 8) {
                    Text(file.displayDate)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.gray))
                    
                    if !file.isFolder && file.size > 0 {
                        Text("•")
                            .foregroundColor(Color(UIColor.lightGray))
                        Text(file.displaySize)
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.gray))
                    }
                    
                    if file.hasShares {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.darkBlue))
                    }
                    
                    Spacer()
                }
                
                // Upload progress
                if file.fileStatus == .uploading {
                    ProgressView(value: 0.5)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.darkBlue)))
                        .frame(height: 2)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
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
                    Image(systemName: file.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(Color(UIColor.lightGray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemGray6))
                }
                .indicator(.activity)
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                Color(UIColor.systemGray6)
                Image(systemName: file.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.darkBlue))
            }
        }
    }
    
    @ViewBuilder
    private var rightButton: some View {
        if file.isSelectionMode {
            Image(file.isSelected ? "fullCheckbox" : "emptyCheckbox")
                .renderingMode(.template)
                .foregroundColor(file.isSelected ? Color(UIColor.darkBlue) : Color(UIColor.lightGray))
                .frame(width: 24, height: 24)
        } else if file.canShowMore {
            Button(action: { onMoreTap?() }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.darkBlue))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FileListItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            FileListItemView(
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
            
            Divider()
            
            FileListItemView(
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
        .previewLayout(.sizeThatFits)
    }
}
#endif
