//
//  StorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2023.

import SwiftUI

struct StorageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: StorageViewModel
    
    init(viewModel: StateObject<StorageViewModel>) {
        self._viewModel = viewModel
    }
    
    var dismissAction: ((Bool) -> Void)?
    
    var body: some View {
        ZStack {
            CustomNavigationView {
                ZStack {
                    backgroundView
                    contentView
                }
                .ignoresSafeArea(.all)
            } leftButton: {
                backButton
            } rightButton: {
                EmptyView()
            }
        }
        .onChange(of: viewModel.showRedeemNotif) { showNotif in
            withAnimation {
                viewModel.showRedeemNotifView = showNotif
            }
        }
        .sheet(isPresented: $viewModel.addStorageIsPresented) {
        } content: {
            AddStorageView()
        }
        .sheet(isPresented: $viewModel.giftStorageIsPresented) {
        } content: {
            GiftStorageView(viewModel: StateObject(wrappedValue: GiftStorageViewModel(accountData: viewModel.accountData)))
        }
        .sheet(isPresented: $viewModel.redeemStorageIspresented) {
        } content: {
            RedeemCodeView(viewModel: RedeemCodeViewModel(accountData: viewModel.accountData, redeemCode: viewModel.redeemCodeFromUrl)) { ammount in
                viewModel.redeemAmmountInt = ammount
                viewModel.redeemCodeFromUrl = nil
            }
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            if viewModel.showRedeemNotifView {
                BottomInfoMessageView(alertTextTitle: "Gift code redeemed.", alertTextDescription: "\(viewModel.redeemAmmountConverted) of storage") {
                    viewModel.showRedeemNotif = false
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                .padding(.bottom, 10)
                .padding(.horizontal)
            }
            VStack {
                GradientProgressBarView(value: viewModel.spaceUsedReadable, maxValue: viewModel.spaceTotalReadable, sizeRatio: viewModel.spaceRatio, colorScheme: .gradientWithWhiteBar)
                Button {
                    viewModel.addStorageIsPresented = true
                } label: {
                    CustomListItemView(image: Image(.storagePlus), titleText: "Add storage", descText: "Increase your space easily by adding more storage.")
                }
                Divider()
                Button {
                    viewModel.giftStorageIsPresented = true
                } label: {
                    CustomListItemView(image: Image(.storageGift), titleText: "Gift storage", descText: "Share storage with others by gifting it to friends or collaborators.")
                }
                Divider()
                Button {
                    viewModel.redeemStorageIspresented = true
                } label: {
                    CustomListItemView(image: Image(.storageRedeem), titleText: "Redeem code", descText: "Enter codes to unlock special storage benefits just for you.")
                }
                Spacer()
            }
        }
        .navigationBarTitle("Storage", displayMode: .inline)
        .padding(.top, 10)
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Image(.backArrowNewDesign)
                    .foregroundColor(.white)
            }
        }
    }
    
    func dismissView() {
        dismissAction?(false)
        presentationMode.wrappedValue.dismiss()
    }
}
