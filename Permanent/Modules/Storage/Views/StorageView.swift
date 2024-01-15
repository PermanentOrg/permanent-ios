//
//  StorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2023.

import SwiftUI

struct StorageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: StorageViewModel
    @State var addStorageIsPresented: Bool = false
    @State var giftStorageIsPresented: Bool = false
    @State var redeemStorageIspresented: Bool = false
    @State private var showRedeemNotifView = false
    
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
                showRedeemNotifView = showNotif
            }
        }
        .sheet(isPresented: $addStorageIsPresented) {
        } content: {
            AddStorageView()
        }
        .sheet(isPresented: $giftStorageIsPresented) {
        } content: {
            GiftStorageView(viewModel: StateObject(wrappedValue: GiftStorageViewModel(accountData: viewModel.accountData)))
        }
        .sheet(isPresented: $redeemStorageIspresented) {
        } content: {
            RedeemCodeView(viewModel: RedeemCodeViewModel(accountData: viewModel.accountData)) { ammount in
                viewModel.redeemAmmountInt = ammount
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
            if showRedeemNotifView {
                BottomInfoMessageView(alertTextTitle: "Gift code redeemed!", alertTextDescription: "\(viewModel.redeemAmmountConverted) of storage") {
                    viewModel.showRedeemNotif = false
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                .padding(.bottom, 10)
                .padding(.horizontal)
            }
            VStack {
                GradientProgressBarView(value: viewModel.spaceUsedReadable, maxValue: viewModel.spaceTotalReadable, sizeRatio: viewModel.spaceRatio)
                Button {
                    addStorageIsPresented = true
                } label: {
                    CustomListItemView(image: Image(.storagePlus), titleText: "Add storage", descText: "Increase your space easily by adding more storage.")
                }
                Divider()
                Button {
                    giftStorageIsPresented = true
                } label: {
                    CustomListItemView(image: Image(.storageGift), titleText: "Gift storage", descText: "Share storage with others by gifting it to friends or collaborators.")
                }
                Divider()
                Button {
                    redeemStorageIspresented = true
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
