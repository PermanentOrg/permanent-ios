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
    var fontType: FontType = .openSans
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
                            TitleText(fontType: fontType, text: titleText)
                        }
                        DescriptionText(fontType: fontType, text: descText)
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

fileprivate struct TitleText: View {
    var fontType: FontType
    var text: String
    
    var body: some View {
        if fontType == .usual {
            Text(text)
                .textStyle(UsualSmallXSemiBoldTextStyle())
                .foregroundColor(.blue900)
        } else {
            Text(text)
                .textStyle(SmallXSemiBoldTextStyle())
                .foregroundColor(.blue900)
        }
    }
}

fileprivate struct DescriptionText: View {
    var fontType: FontType
    var text: String
    
    var body: some View {
        if fontType == .usual {
            Text(text)
                .textStyle(UsualSmallXXXRegularTextStyle())
                .foregroundColor(.blue400)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        } else {
            Text(text)
                .textStyle(SmallXXXRegularTextStyle())
                .foregroundColor(.blue400)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}
