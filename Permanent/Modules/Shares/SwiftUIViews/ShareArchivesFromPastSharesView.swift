//
//  ShareArchivesFromPastSharesView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

struct ShareArchivesFromPastSharesView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @StateObject private var archivesViewModel = ShareArchivesFromPastSharesViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var isKeyboardVisible: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 26.0, *) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .frame(height: 72)
                    .background(Color.white)
            } else {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .frame(height: 64)
                    .background(Color.white)
            }

            if #unavailable(iOS 26.0) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                    .background(Color.blue50)
            }

            searchSection
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.blue25)

            if archivesViewModel.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.1)
                    Text("Loading archives...")
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundColor(Color.blue300)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        archiveSection(
                            title: "MY ARCHIVES",
                            archives: archivesViewModel.myArchives
                        )
                        .padding(.top, 24)

                        archiveSection(
                            title: "OTHER ARCHIVES",
                            archives: archivesViewModel.otherArchives
                        )
                        .padding(.top, archivesViewModel.myArchives.isEmpty ? 24 : 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .onTapGesture {
                    dismissKeyboard()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            archivesViewModel.fetchArchives()
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
                if #available(iOS 26.0, *) {
                    Button(action: {
                        if isKeyboardVisible || isSearchFocused {
                            dismissKeyboard()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                viewModel.closeSelectArchiveFromPastShares()
                            }
                        } else {
                            viewModel.closeSelectArchiveFromPastShares()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.custom("Usual-Regular", size: 24))
                            .frame(width: 36, height: 36)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .contentShape(.circle)
                    .controlSize(.regular)
                    .padding(.leading, -12)
                } else {
                    Button(action: {
                        if isKeyboardVisible || isSearchFocused {
                            dismissKeyboard()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                viewModel.closeSelectArchiveFromPastShares()
                            }
                        } else {
                            viewModel.closeSelectArchiveFromPastShares()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.blue900)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                }
                Spacer()
            }

            Text(archivesViewModel.title)
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)

            HStack {
                Spacer()
                if #available(iOS 26.0, *) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.custom("Usual-Regular", size: 24))
                            .frame(width: 36, height: 36)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .contentShape(.circle)
                    .controlSize(.regular)
                    .padding(.trailing, -12)
                } else {
                    Button(action: { dismiss() }) {
                        Image(.closeButtonV2)
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.86, green: 0.29, blue: 0.48), Color(red: 0.98, green: 0.68, blue: 0.23)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .background(Color.blue25)
                .cornerRadius(4)

            TextField("Filter archives...", text: $archivesViewModel.searchText)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(Color.blue900)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color.blue50, lineWidth: 1)
        )
    }

    private func archiveSection(title: String, archives: [ShareArchivesFromPastSharesViewModel.PastSharedArchive]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !archives.isEmpty {
                Text(title)
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue300)
                    .tracking(2)
                    .padding(.bottom, 8)
            }

            ForEach(archives) { archive in
                archiveRow(archive)
                    .padding(.vertical, 12)
            }
        }
    }

    private func archiveRow(_ archive: ShareArchivesFromPastSharesViewModel.PastSharedArchive) -> some View {
        Button(action: {
            dismissKeyboard()
            viewModel.openGrantArchiveAccess(
                archiveName: archive.title,
                archiveInitials: archive.initials,
                archiveID: archive.archiveID,
                thumbnailURL: archive.thumbnailURL,
                source: .pastShares
            )
        }) {
            HStack(spacing: 16) {
                archiveThumbnail(thumbnailURL: archive.thumbnailURL, initials: archive.initials)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(archive.title)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.blue200)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func archiveThumbnail(thumbnailURL: String?, initials: String) -> some View {
        if let thumbnailURL, let url = URL(string: thumbnailURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    initialsAvatar(initials)
                }
            }
        } else {
            initialsAvatar(initials)
        }
    }

    private func initialsAvatar(_ initials: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.62, green: 0.15, blue: 0.57), Color(red: 0.95, green: 0.55, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 3) {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)

                Text(initials)
                    .font(.custom("Usual-Medium", size: 12))
                    .foregroundColor(.white)
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func dismissKeyboard() {
        isSearchFocused = false
        hideKeyboard()
    }
}
