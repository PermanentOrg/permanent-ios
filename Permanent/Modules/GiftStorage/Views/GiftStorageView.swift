//
//  GiftStorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.10.2023.

import SwiftUI

struct GiftStorageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: GiftStorageViewModel
    
    var dismissAction: ((Bool) -> Void)?
    
    var body: some View {
        CustomNavigationView {
            ZStack {
                backgroundView
                contentView
            }
        } leftButton: {
            backButton
        } rightButton: {
            EmptyView()
        }
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Text("Back")
                    .foregroundColor(.white)
            }
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        VStack(spacing: 32) {
            progressBarStorageView
            giftStorageInfoView
            Spacer()
        }
        .padding(32)
        .navigationBarTitle("Gift Storage", displayMode: .inline)
    }
    
    var progressBarStorageView: some View {
        VStack(spacing: 10) {
            ProgressView(value: viewModel.spaceRatio)
                .progressViewStyle(CustomBarProgressStyle(color: .barneyPurple, height: 12))
                .frame(height: 12)
            storageInfoTextView
        }
    }
    
    var storageInfoTextView: some View {
        HStack {
            Text("\(viewModel.spaceTotalReadable) Storage")
                .textStyle(SmallXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
                .multilineTextAlignment(.leading)
            Spacer()
            Text("\(viewModel.spaceLeftReadable) free")
                .textStyle(SmallXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
                .multilineTextAlignment(.trailing)
                .padding(.trailing, 4)
        }
    }
    
    var giftStorageInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gift storage with others".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
            Text("Send storage to both existing users and new sign-ups. They need to log in or create an account to get your gift.")
                .textStyle(MediumSemiBoldTextStyle())
                .foregroundColor(.darkBlue)
        }
        .padding(.horizontal, -1)
    }
    
    func dismissView() {
        dismissAction?(false)
        presentationMode.wrappedValue.dismiss()
    }
    
    func dismissViewWithAssets() {
        presentationMode.wrappedValue.dismiss()
    }
}
