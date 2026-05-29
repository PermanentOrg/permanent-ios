//
//  ShareArchivesFromPastSharesView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

struct ShareArchivesFromPastSharesView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @ObservedObject private var archivesViewModel: ShareArchivesFromPastSharesViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ShareItemViewModel) {
        self.viewModel = viewModel
        self.archivesViewModel = viewModel.pastSharesViewModel
    }
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
            } else if archivesViewModel.myArchives.isEmpty && archivesViewModel.otherArchives.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text(archivesViewModel.searchText.isEmpty
                         ? "No archives from past shares"
                         : "No archives match your search")
                        .font(.custom("Usual-Medium", size: 16))
                        .foregroundColor(Color.blue900)
                    Text(archivesViewModel.searchText.isEmpty
                         ? "Archives you've previously shared with will appear here."
                         : "Try a different search term.")
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundColor(Color.blue300)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if !archivesViewModel.myArchives.isEmpty {
                            archiveSection(
                                title: "MY ARCHIVES",
                                archives: archivesViewModel.myArchives
                            )
                            .padding(.top, 24)
                        }

                        if !archivesViewModel.otherArchives.isEmpty {
                            archiveSection(
                                title: "OTHER ARCHIVES",
                                archives: archivesViewModel.otherArchives
                            )
                            .padding(.top, archivesViewModel.myArchives.isEmpty ? 24 : 20)
                        }
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
                    .font(.custom("Usual-Regular", size: 10))
                    .foregroundColor(Color.blue900)
                    .tracking(1.6)
                    .padding(.bottom, 8)
            }

            ForEach(archives) { archive in
                archiveRow(archive)
                    .padding(.vertical, 12)
            }
        }
    }

    private func archiveRow(_ archive: ShareArchivesFromPastSharesViewModel.PastSharedArchive) -> some View {
        let hasAccess = archivesViewModel.hasAccess(archive)

        return Group {
            if hasAccess {
                archiveRowContent(archive, hasAccess: true)
            } else {
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
                    archiveRowContent(archive, hasAccess: false)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func archiveRowContent(_ archive: ShareArchivesFromPastSharesViewModel.PastSharedArchive, hasAccess: Bool) -> some View {
        HStack(spacing: 16) {
            archiveThumbnail(thumbnailURL: archive.thumbnailURL)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(hasAccess ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(archive.title)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(hasAccess ? Color.blue300 : Color.blue900)
                    .lineLimit(1)

                if hasAccess {
                    Text("Already has access to this share")
                        .font(.custom("Usual-Regular", size: 12))
                        .foregroundColor(Color.success500)
                        .lineLimit(1)
                }
            }

            Spacer()

            if hasAccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color.blue200)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.blue200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func archiveThumbnail(thumbnailURL: String?) -> some View {
        CachedAsyncImage(url: thumbnailURL.flatMap { URL(string: $0) }) {
            Image(.shareArchivePending)
                .cornerRadius(8)
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
