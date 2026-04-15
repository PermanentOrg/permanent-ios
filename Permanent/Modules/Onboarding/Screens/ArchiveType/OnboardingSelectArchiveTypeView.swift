//
//  OnboardingSelectArchiveTypeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.04.2024.
//

import SwiftUI

struct OnboardingSelectArchiveTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: OnboardingSelectArchiveTypeViewModel
    private let visibleArchiveTypes = ArchiveType.allCases.filter { $0 != .nonProfit }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernBody
            } else {
                legacyBody
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @available(iOS 26.0, *)
    private var modernBody: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(visibleArchiveTypes, id: \.onboardingType) { item in
                        Button {
                            viewModel.containerViewModel.archiveType = item
                            dismiss()
                        } label: {
                            ArchiveTypeView(
                                archiveType: item,
                                showsDivider: item != visibleArchiveTypes.last
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Archive Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var legacyBody: some View {
        VStack {
            if Constants.Design.isPhone {
                legacyPhoneBody
            } else {
                legacyPadBody
            }
        }
    }

    private var legacyPhoneBody: some View {
        legacySheetBody {
            Text("Archive Type")
                .textStyle(UsualRegularMediumTextStyle())
                .accentColor(.blue900)
        }
    }

    private var legacyPadBody: some View {
        legacySheetBody {
            Text("Archive Type")
                .textStyle(UsualMediumTextStyle())
                .accentColor(.blue900)
        }
    }

    private func legacySheetBody<Title: View>(@ViewBuilder title: () -> Title) -> some View {
        VStack {
            VStack(alignment: .center) {
                Spacer()
                ZStack(alignment: .trailing) {
                    HStack(alignment: .center) {
                        Spacer()
                        title()
                        Spacer()
                    }
                    Button {
                        dismiss()
                    } label: {
                        Image(.newCloseButton)
                            .renderingMode(.template)
                            .foregroundColor(.black)
                            .frame(width: 16, height: 16)
                    }
                    .padding(.trailing, 16)
                }
                Spacer()
                Divider()
                    .frame(height: 1)
            }
            .frame(height: 64)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(visibleArchiveTypes, id: \.onboardingType) { item in
                        Button {
                            viewModel.containerViewModel.archiveType = item
                            dismiss()
                        } label: {
                            ArchiveTypeView(archiveType: item,
                            showsDivider: item != visibleArchiveTypes.last
                            )
                        }
                    }
                }
            }
            Spacer()
        }
    }
}
