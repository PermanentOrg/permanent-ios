//
//  OnboardingArchiveName.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.04.2024.

import SwiftUI

struct OnboardingArchiveNameView: View {
    @State var presentSelectArchivesType: Bool = false
    @State private var dynamicHeight: CGFloat = 0
    @ObservedObject var viewModel: OnboardingArchiveNameViewModel
    
    var backButton: (() -> Void)
    var nextButton: (() -> Void)
    @State var isKeyboardPresented = false
    @State var textFieldText: String = ""
    
    var body: some View {
        if Constants.Design.isPhone {
            iPhoneBody
        } else {
            iPadBody
        }
    }
    
    var iPhoneBody: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            OnboardingTitleTextView(
                                preText: "Create your \n",
                                boldText: "\(viewModel.containerViewModel.archiveType.onboardingType)",
                                postText: "\(viewModel.containerViewModel.archiveType == .familyHistory ? "\n" : " ")archive"
                            )
                            .onTapGesture {
                                dismissKeyboard()
                            }
                            Text("Name your new archive. This is the formal or official name of the person, family, group, or organization the archive represents. You can edit the name later if needed.")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                                .onTapGesture {
                                    dismissKeyboard()
                                }
                            CustomBorderTextField(textFieldText: $viewModel.containerViewModel.archiveName, placeholder: "Name...")
                            Spacer(minLength: 90)
                                .id(0)
                                .onTapGesture {
                                    dismissKeyboard()
                                }
                        }
                    }
                    .onReceive(keyboardPublisher) { keyboard in
                        if keyboard.isFirstResponder {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                withAnimation {
                                    scrollReader.scrollTo(0, anchor: .center)
                                }
                            })
                        }
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                }
                HStack(alignment: .center) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                    SmallRoundButtonImageView(isDisabled: viewModel.containerViewModel.archiveName.isEmpty, text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
                .sheet(isPresented: $presentSelectArchivesType, content: {
                    OnboardingSelectArchiveTypeView(viewModel: OnboardingSelectArchiveTypeViewModel(containerViewModel: viewModel.containerViewModel))
                })
            }
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            ScrollView(showsIndicators: false) {
                VStack {
                    HStack() {
                        OnboardingTitleTextView(
                            preText: "Create your \n",
                            boldText: "\(viewModel.containerViewModel.archiveType.onboardingType)",
                            postText: "\nArchive"
                        )
                        Spacer()
                    }
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 64) {
                            Text("Name your new archive. This is the formal or official name of the person, family, group, or organization the archive represents. You can edit the name later if needed.")
                                .textStyle(UsualRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                                .onTapGesture {
                                    dismissKeyboard()
                                }
                            CustomBorderTextField(textFieldText: $viewModel.containerViewModel.archiveName, placeholder: "Name...")
                            Spacer(minLength: 60)
                                .id(1)
                                .onTapGesture {
                                    dismissKeyboard()
                                }
                        }
                    }
                    .onReceive(keyboardPublisher) { keyboard in
                        if keyboard.isFirstResponder {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                withAnimation {
                                    scrollReader.scrollTo(1, anchor: .center)
                                }
                            })
                        }
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                }
                HStack(spacing: 32) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                    RoundButtonRightImageView(isDisabled: viewModel.containerViewModel.archiveName.isEmpty, text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
