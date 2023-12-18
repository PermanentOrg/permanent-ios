//
//  CustomListItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

struct CustomListItemView: View {
    var image: Image
    var titleText: String
    var descText: String
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 24) {
                image
                    .resizable()
                    .foregroundColor(.blue900)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 10)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(titleText)
                            .textStyle(SmallXSemiBoldTextStyle())
                            .foregroundColor(.blue900)
                        if titleText == "Redeem code" {
                            NewBadgeView()
                        }
                    }
                    Text(descText)
                        .textStyle(SmallXXXRegularTextStyle())
                        .foregroundColor(.blue400)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue400)
                    .padding(.trailing, 10)
            }
            .padding(10)
        }
    }
}
