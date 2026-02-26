//
//  FindArchiveByEmailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

struct FindArchiveByEmailView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var isKeyboardVisible: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(height: 64)
                .background(Color.white)

            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                .background(Color.blue50)

            VStack(spacing: 0) {
                searchSection
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSearchFocused {
                    isSearchFocused = false
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom) {
            bottomActionSection
                .padding(.bottom, isKeyboardVisible ? 24 : 0)
                .background(Color.white)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if isSearchFocused {
                    isSearchFocused = false
                }
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isSearchFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: {
                    if isSearchFocused {
                        isSearchFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            viewModel.closeFindArchiveByEmail()
                        }
                    } else {
                        viewModel.closeFindArchiveByEmail()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.blue900)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                Spacer()
            }

            Text("Find an archive using email")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)

            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(.closeButtonV2)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    private var searchSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.97))

            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.86, green: 0.29, blue: 0.48), Color(red: 0.98, green: 0.68, blue: 0.23)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32, alignment: .center)
                    .background(Color.blue25)
                    .cornerRadius(4)

                TextField("Email address...", text: $viewModel.searchText)
                    .focused($isSearchFocused)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.blue200)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(Color.blue50, lineWidth: 1)
            )
            .padding(8)
        }
        .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64, alignment: .leading)
    }

    private var bottomActionSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(.clear)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .background(Color.blue50)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Button(action: {
                if isSearchFocused {
                    isSearchFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        viewModel.openSelectArchiveFromPastShares()
                    }
                } else {
                    viewModel.openSelectArchiveFromPastShares()
                }
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.07, green: 0.11, blue: 0.29), location: 0.00),
                                    Gradient.Stop(color: Color(red: 0.21, green: 0.27, blue: 0.57), location: 1.00)
                                ],
                                startPoint: UnitPoint(x: 0, y: 0),
                                endPoint: UnitPoint(x: 1, y: 1)
                            )
                        )
                        .cornerRadius(6)

                    Text("Select an archive from past shares")
                        .font(.custom("Usual-Medium", size: 14))
                        .foregroundColor(Color.blue900)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.blue200)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                //.padding(.vertical, 12)
                .padding(.horizontal, 24)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 24)
            .background(Color.white)
        }
    }
}
