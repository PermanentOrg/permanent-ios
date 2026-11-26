//
//  SectionHeaderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.07.2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct SectionHeaderView: View {
    @Binding var selectedFiles: [FileModel]
    
    var body: some View {
        VStack {
            HStack {
                let files = selectedFiles
                    if !files.isEmpty, let url = URL(string: files.first?.preferredThumbnailURL) {
                        WebImage(url: url)
                            .resizable()
                            .placeholder(content: {
                                VStack {
                                    Image("questionMark")
                                }
                            })
                            .frame(width: 24, height: 24)
                            .aspectRatio(contentMode: .fill)
                    }
                    Text(Self.title(fileCount: files.count))
                        .textStyle(SmallBoldTextStyle())
                Spacer()
            }
        }
        .padding(.top, 24)
    }

    static func title(fileCount: Int) -> String {
        fileCount == 1 ? "EditFileMetadataTitle".localized() : String(format: "EditingItemsCount".localized(), fileCount)
    }
}

struct SectionHeaderView_Previews: PreviewProvider {
    @State static var files: [FileModel] = []
    
    static var previews: some View {
        SectionHeaderView(selectedFiles: $files)
    }
}
