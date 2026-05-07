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
        HStack(spacing: 10) {
            if let urlString = thumbnailURL, let url = URL(string: urlString) {
                WebImage(url: url)
                    .resizable()
                    .placeholder {
                        Image(.shareArchivePending)
                            .cornerRadius(6)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.15))
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(.shareArchivePending)
                    .cornerRadius(6)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 0) {
                    Text("Shared by ") +
                    Text(sharedByName).fontWeight(.semibold) +
                    Text(" from")
                }
                .font(.custom("Usual", size: 12))
                .foregroundColor(.blue600)
                
                HStack(alignment: .center, spacing: 0) {
                    Text("The ") +
                    Text(archiveName).fontWeight(.semibold) +
                    Text(" Archive")
                }
                .font(.custom("Usual", size: 14))
                .foregroundColor(.blue900)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.blue25)
    }
}

struct SharePreviewHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewHeaderView(shareName: "AquaPark Party", sharedByName: "Robert Friedman", archiveName: "Family", thumbnailURL: nil)
            .previewLayout(.sizeThatFits)
    }
}
