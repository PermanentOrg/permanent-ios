//
//  GiftStorageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.10.2023.

import SwiftUI

struct GiftStorageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: GiftStorageViewModel
    
    init(viewModel: StateObject<GiftStorageViewModel>) {
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
                    .edgesIgnoringSafeArea(.all)
            } leftButton: {
                backButton
            } rightButton: {
                EmptyView()
            }
            .onTapGesture {
                dismissKeyboard()
            }
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "Are you sure you’d like to gift storage? This can't be undone!", message: nil, buttonTitle: "Yes, gift storage", addCornerRadius: true) {
                    viewModel.changesConfirmed = true
                }
                .frame(width: 294)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.sentGiftDialogWasSuccessfull) { error in
            Alert(title: Text("Storage successfully gifted"), message: Text("Success! You sent \(viewModel.giftAmountValue) GB of Permanent storage"), dismissButton: .default(Text(String.ok)) {
                viewModel.sentGiftDialogWasSuccessfull = false
                dismissView()
            })
        }
        .alert(isPresented: $viewModel.sentGiftDialogError) {
            Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                viewModel.sentGiftDialogError = false
            })
        }
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
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                progressBarStorageView
                giftStorageInfoView
                recipientEmailsView
                addStorageAmountView
                noteToRecipients
                sendGiftStorageButton
                Spacer()
            }
            .padding(32)
            .navigationBarTitle("Gift Storage", displayMode: .inline)
        }
        .padding(.top, -10)
        .frame(maxHeight: .infinity)
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
            Text("Gift storage to others".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
            Text("Send storage to existing users or invite someone new with a gift. Recipients must create an account to claim a gift.")
                .textStyle(MediumSemiBoldTextStyle())
                .foregroundColor(.darkBlue)
        }
        .padding(.horizontal, -1)
    }
    
    var addStorageAmountView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gift".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
            CustomStepper(value: $viewModel.giftAmountValue, textColor: .darkBlue, borderColor: $viewModel.giftBorderColor)
            
            if let amountText = viewModel.amountText {
                Text("\(amountText)")
                    .textStyle(SmallXXXXXItalicTextStyle())
                    .foregroundColor(viewModel.notEnoughStorageSpace ? .lightRed : .darkBlue)
            }

        }
    }
    
    var noteToRecipients: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Text("Note to Recipients".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(.liniarBlue)
                Text(" (Optional)".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(.lightGray)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .inset(by: 0.5)
                            .stroke(Color.galleryGray, lineWidth: 1))
                TextView(text: $viewModel.noteText,
                         didSaved: $viewModel.didSavedNoteText,
                         textStyle: TextFontStyle.style39,
                         textColor: .middleGray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxHeight: 80)
            }
            .frame(height: 88)
            .foregroundColor(.clear)
        }
    }
    
    var sendGiftStorageButton: some View {
        Button(action: {
            sendGiftStorage()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isSendButtonDisabled ? Color(red: 0.72, green: 0.73, blue: 0.79) : .darkBlue)
                    .frame(height: 56)
                HStack {
                    Text("Send gift storage")
                        .textStyle(SmallSemiBoldTextStyle())
                        .foregroundColor(.white)
                    Spacer()
                    Image(.legacyPlanRightArrow)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .disabled(viewModel.isSendButtonDisabled)
    }
    
    func sendGiftStorage() {
        viewModel.showConfirmation = true
    }
    
    var recipientEmailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recipient emails".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(.liniarBlue)
            EmailChipView(emails: $viewModel.emails)
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

    func feedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
