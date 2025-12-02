//
//  FABMenuItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2025.

import SwiftUI

struct FABMenuItemView: View {
    let systemIcon: String?
    let assetImage: Image?
    let title: String
    var isBold: Bool = false
    let action: () -> Void
    
    init(systemIcon: String? = nil, assetImage: Image? = nil, title: String, isBold: Bool = false, action: @escaping () -> Void) {
        self.systemIcon = systemIcon
        self.assetImage = assetImage
        self.title = title
        self.isBold = isBold
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 20, weight: .regular))
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                } else if let assetImage = assetImage {
                    assetImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                }
                
                Text(title)
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(isBold ? .medium : .regular)
                    .foregroundColor(.blue900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(NoHighlightButtonStyle())
    }
}
