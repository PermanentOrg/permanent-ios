//
//  CustomSimpleListItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.02.2024.

import SwiftUI

/// Description: Simple list element containing an image and a text
struct CustomSimpleListItemView: View {
    var image: Image
    var titleText: String
    var color: Color = .blue900
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 24) {
                image
                    .resizable()
                    .foregroundColor(color)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 10)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(titleText)
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(color)
                    }
                }
            }
            .padding(10)
        }
    }
}
