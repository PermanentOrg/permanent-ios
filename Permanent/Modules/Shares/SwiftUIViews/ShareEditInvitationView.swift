//
//  ShareEditInvitationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.04.2026.
//

import SwiftUI

struct ShareEditInvitationView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss

    private var recipientName: String {
        viewModel.editingInvitation?.accountVO?.fullName ?? "Invited user"
    }

    private var recipientEmail: String {
        viewModel.editingInvitation?.accountVO?.primaryEmail ?? ""
    }

    private var selectedRole: AccessRole {
        viewModel.selectedRoleForEditInvitation
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
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .overlay {
            RevokeBottomAlertView(
                isPresented: $viewModel.showRevokeInvitationAlert,
                buttonText: "Revoke invitation",
                onRevoke: {
                    viewModel.revokeInvitation()
                },
                titleView: {
                    AnyView(
                        Group {
                            Text("Are you sure you want to revoke this invitation to\nThe ")
                            + Text(recipientName).fontWeight(.semibold)
                            + Text(" Archive?")
                        }
                    )
                }
            )
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let errorMessage = viewModel.errorMessage { Text(errorMessage) }
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        viewModel.closeEditInvitation()
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
                        viewModel.closeEditInvitation()
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

            Text("Edit invitation")
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

                Text(recipientName)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.blue25)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("RECIPIENT EMAIL ADDRESS")

                Text(recipientEmail)
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.blue25)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("ACCESS ROLE")

                HStack(spacing: 16) {
                    selectedRole.icon
                        .renderingMode(.template)
                        .foregroundColor(Color.blue900)
                        .frame(width: 32, height: 32)
                        .background(Color.blue25)
                        .cornerRadius(4)

                    Text(selectedRole.title)
                        .font(.custom("Usual-Medium", size: 14))
                        .foregroundColor(Color.blue900)

                    Spacer()
                }
                .padding(.top, 12)
            }

            Rectangle()
                .fill(Color.blue50)
                .frame(height: 1)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    viewModel.resendInvitation()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.blue900)
                            .frame(width: 24, height: 24)

                        Text("Send again")
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(Color.blue900)

                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.showRevokeInvitationAlert = true
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.error500)
                            .frame(width: 24, height: 24)

                        Text("Revoke invitation")
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(Color.error500)

                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.closeEditInvitation()
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
                viewModel.closeEditInvitation()
            }) {
                Text("Done")
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue900)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
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

    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Please wait...")
                        .foregroundColor(.white)
                        .font(.body)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            )
            .ignoresSafeArea()
    }
}
