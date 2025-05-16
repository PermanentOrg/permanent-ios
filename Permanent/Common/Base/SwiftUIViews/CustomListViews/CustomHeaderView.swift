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
    var showFinishSetUpAccount: Bool = false
    var onFinishSetUpAccount: (() -> Void)
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.blue25
                .frame(maxWidth: .infinity, maxHeight: showFinishSetUpAccount ? 161 : 88)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 10) {
                    WebImage(url: url)
                        .resizable()
                        .foregroundColor(.blue900)
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                    VStack(alignment: .leading, spacing: 4) {
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
                if showFinishSetUpAccount {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                        .background(Color(red: 0.91, green: 0.91, blue: 0.93))
                        .padding(.horizontal)
                    Button {
                        onFinishSetUpAccount()
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(.memberChecklistShowList)
                                .renderingMode(.template)
                                .resizable()
                                .foregroundColor(.blue900)
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(.circle)
                                .padding(.horizontal, 8)
                            Text("Let’s finish setting up your account")
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        fixedSize: 14)
                                )
                                .foregroundColor(.blue900)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: showFinishSetUpAccount ? 161 : 88)
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
