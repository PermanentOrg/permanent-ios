//
//  CustomHeaderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.02.2024.
import SwiftUI
import SDWebImageSwiftUI

struct CustomHeaderView: View {
    var url: URL?
    var titleText: String
    var descText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.blue25
                .frame(maxWidth: .infinity, maxHeight: 88)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack(alignment: .center, spacing: 16) {
                    WebImage(url: url)
                        .resizable()
                        .foregroundColor(.blue900)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            Text(titleText)
                                .textStyle(SmallXSemiBoldTextStyle())
                                .foregroundColor(.blue900)
                        }
                        Text(descText)
                            .textStyle(SmallXXXRegularTextStyle())
                            .foregroundColor(.blue400)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(.closeSettings)
                            .foregroundColor(.blue900)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
