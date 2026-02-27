//
//  ShareFindArchiveByEmailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI
import UIKit

struct ShareFindArchiveByEmailView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @ObservedObject private var findArchiveViewModel: ShareFindArchiveByEmailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSearchFocused: Bool = false
    @State private var isKeyboardVisible: Bool = false

    init(viewModel: ShareItemViewModel) {
        self.viewModel = viewModel
        self._findArchiveViewModel = ObservedObject(wrappedValue: viewModel.findArchiveByEmailViewModel)
    }

    private var contentBackgroundColor: Color {
        switch findArchiveViewModel.visibleSearchOutcome {
        case .noAccount:
            return .blue25
        default:
            return .white
        }
    }

    private func handleSearchSubmit() {
        _ = findArchiveViewModel.performSearch()
    }

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

                Group {
                    switch findArchiveViewModel.visibleSearchOutcome {
                    case .found(let archives):
                        mockResultsSection(archives)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    case .noAccount(let email):
                        noAccountSection(email)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    case .idle:
                        EmptyView()
                            .transition(.opacity)
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSearchFocused {
                    isSearchFocused = false
                }
            }
            .background(contentBackgroundColor)
            .animation(.easeInOut(duration: 0.2), value: findArchiveViewModel.visibleOutcomeState)
        }
        .background(Color.white)
        .safeAreaInset(edge: .bottom) {
            if case .noAccount = findArchiveViewModel.visibleSearchOutcome {
                noAccountBottomInviteSection
                    .padding(.bottom, 24)
                    .background(Color.blue25)
            } else {
                bottomActionSection
                    .padding(.bottom, isKeyboardVisible ? 24 : 0)
                    .background(Color.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: findArchiveViewModel.visibleOutcomeState)
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
        .onChange(of: findArchiveViewModel.searchText) { _ in
            findArchiveViewModel.handleTextChanged()
        }
        .onChange(of: findArchiveViewModel.visibleOutcomeState) { newValue in
            if newValue != 0, isSearchFocused {
                isSearchFocused = false
            }
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

                SubmitControlledTextField(
                    text: $findArchiveViewModel.searchText,
                    isFirstResponder: $isSearchFocused,
                    placeholder: "Email address...",
                    onSubmit: {
                        handleSearchSubmit()
                        return findArchiveViewModel.visibleOutcomeState != 0
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !findArchiveViewModel.searchText.isEmpty {
                    Button(action: {
                        findArchiveViewModel.clearSearch()
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

    private func mockResultsSection(_ archives: [ShareFindArchiveByEmailViewModel.ArchiveResult]) -> some View {
        VStack(spacing: 24) {
            ForEach(archives) { archive in
                mockArchiveRow(archive)
            }
        }
    }

    private func noAccountSection(_ email: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Looks like someone's missing out.")
                .font(.custom("Usual-Medium", size: 24))
                .foregroundColor(Color.blue900)

            (
                Text("We couldn’t find an account for ")
                    .font(.custom("Usual-Regular", size: 13))
                    .foregroundColor(Color.blue900)
                + Text(email)
                    .font(.custom("Usual-Medium", size: 13))
                    .foregroundColor(Color.blue900)
                + Text(". Would you like to invite them to join Permanent and share this file with them once they join?")
                    .font(.custom("Usual-Regular", size: 13))
                    .foregroundColor(Color.blue900)
            )
            .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noAccountBottomInviteSection: some View {
        Button(action: {
            if isSearchFocused || isKeyboardVisible {
                isSearchFocused = false
                if case .noAccount(let email) = findArchiveViewModel.visibleSearchOutcome {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        viewModel.openInviteAndGrantAccess(recipientEmail: email)
                    }
                }
            } else if case .noAccount(let email) = findArchiveViewModel.visibleSearchOutcome {
                viewModel.openInviteAndGrantAccess(recipientEmail: email)
            }
        }) {
            HStack(spacing: 8) {
                Spacer()
                Text("Invite now")
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(.white)
                Image(systemName: "paperplane")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(height: 56)
            .background(Color.blue900)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func mockArchiveRow(_ archive: ShareFindArchiveByEmailViewModel.ArchiveResult) -> some View {
        Button(action: {
            if isSearchFocused || isKeyboardVisible {
                isSearchFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    viewModel.openGrantArchiveAccess(
                        archiveName: archive.name,
                        archiveInitials: archive.initials,
                        source: .findByEmail
                    )
                }
            } else {
                viewModel.openGrantArchiveAccess(
                    archiveName: archive.name,
                    archiveInitials: archive.initials,
                    source: .findByEmail
                )
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.62, green: 0.15, blue: 0.57), Color(red: 0.95, green: 0.55, blue: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(8)

                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 14, height: 2)

                        Text(archive.initials)
                            .font(.custom("Usual-Medium", size: 10))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 40, height: 40)

                Text(archive.name)
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
                .padding(.horizontal, 24)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 24)
            .background(Color.white)
        }
    }
}

private struct SubmitControlledTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    let placeholder: String
    let onSubmit: () -> Bool

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.text = text
        textField.placeholder = placeholder
        textField.returnKeyType = .search
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .never
        textField.textColor = UIColor(Color.blue900)
        textField.tintColor = UIColor(Color.blue900)
        textField.font = UIFont(name: "Usual-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        if isFirstResponder, !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFirstResponder, uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SubmitControlledTextField

        init(_ parent: SubmitControlledTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFirstResponder = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFirstResponder = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
        }
    }
}
