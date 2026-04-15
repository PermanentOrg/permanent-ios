//
//  ShareInviteAndGrantAccessView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.02.2026.
//

import SwiftUI

struct ShareInviteAndGrantAccessView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case fullName
        case email
    }

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

            content

            Spacer(minLength: 0)

            bottomActions
                .background(Color.white)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboardIfNeeded()
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        dismissKeyboardIfNeeded()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            viewModel.closeInviteAndGrantAccess()
                        }
                    }) {
                        Image(systemName: "arrow.left")
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
                        dismissKeyboardIfNeeded()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            viewModel.closeInviteAndGrantAccess()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.blue900)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                }
                Spacer()
            }

            Text("Invite and grant access")
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

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("RECIPIENT FULL NAME")

                TextField("", text: $viewModel.invitationRecipientFullName)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .focused($focusedField, equals: .fullName)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(Color.blue50, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("RECIPIENT EMAIL ADDRESS")

                TextField("", text: $viewModel.invitationRecipientEmail)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(Color.blue50, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("ACCESS ROLE")

                Button(action: {
                    dismissKeyboardIfNeeded()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        viewModel.navigationDirection = .forward
                        viewModel.showRoleSelection = true
                    }
                }) {
                    HStack(spacing: 16) {
                        viewModel.selectedRoleForInviteAccess.icon
                            .renderingMode(.template)
                            .foregroundColor(Color.blue900)
                            .frame(width: 32, height: 32)
                            .background(Color.blue25)
                            .cornerRadius(4)

                        Text(viewModel.selectedRoleForInviteAccess.title)
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(Color.blue900)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.blue200)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.closeInviteAndGrantAccess()
            }) {
                Text("Cancel")
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue900)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue25)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                dismissKeyboardIfNeeded()
                viewModel.submitInviteAndGrantAccess()
            }) {
                Text("Send invitation")
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue900)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.custom("Usual-Regular", size: 10))
            .foregroundColor(Color.blue900)
            .tracking(1.6)
            .textCase(.uppercase)
    }

    private func dismissKeyboardIfNeeded() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
