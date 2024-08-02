//
//  OnboardingSelectArchiveTypeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.04.2024.

import SwiftUI

struct OnboardingSelectArchiveTypeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: OnboardingSelectArchiveTypeViewModel
    
    var body: some View {
        VStack {
            if Constants.Design.isPhone {
                iPhoneBody
            } else {
                iPadBody
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    var iPhoneBody: some View {
        VStack {
            VStack(alignment: .center) {
                Spacer()
                ZStack(alignment: .trailing) {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("Archive Type")
                                .textStyle(UsualRegularMediumTextStyle())
                                .accentColor(.blue900)
                            Spacer()
                        }
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(.newCloseButton)
                                .renderingMode(.template)
                                .foregroundColor(.black)
                                .frame(width: 16, height: 16)
                        })
                        .padding(.trailing, 16)
                }
                Spacer()
                Divider()
                    .frame(height: 1)
            }
            .frame(height: 64)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(ArchiveType.allCases, id: \.onboardingType) { item in
                        if item != .nonProfit {
                            Button {
                                viewModel.containerViewModel.archiveType = item
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                ArchiveTypeView(archiveType: item)
                            }
                        }
                    }
                }
            }
            .onAppear {
                UIScrollView.appearance().bounces = false
            }
            .onDisappear {
                UIScrollView.appearance().bounces = true
            }
            Spacer()
        }
    }
    
    var iPadBody: some View {
        VStack {
            VStack(alignment: .center) {
                Spacer()
                ZStack(alignment: .trailing) {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("Archive Type")
                                .textStyle(UsualMediumTextStyle())
                                .accentColor(.blue900)
                            Spacer()
                        }
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(.newCloseButton)
                                .renderingMode(.template)
                                .foregroundColor(.black)
                                .frame(width: 16, height: 16)
                        })
                        .padding(.trailing, 16)
                }
                Spacer()
                Divider()
                    .frame(height: 1)
            }
            .frame(height: 64)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(ArchiveType.allCases, id: \.onboardingType) { item in
                        if item != .nonProfit {
                            Button {
                                viewModel.containerViewModel.archiveType = item
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                ArchiveTypeView(archiveType: item)
                            }
                        }
                    }
                }
            }
            .onAppear {
                UIScrollView.appearance().bounces = false
            }
            .onDisappear {
                UIScrollView.appearance().bounces = true
            }
            Spacer()
        }
    }
}
