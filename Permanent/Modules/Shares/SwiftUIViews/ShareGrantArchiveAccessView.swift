//
//  ShareGrantArchiveAccessView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.02.2026.
//

import SwiftUI

struct ShareGrantArchiveAccessView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss

    private var archiveName: String {
        viewModel.pendingArchiveGrant?.name ?? "Archive"
    }

    private var archiveInitials: String {
        viewModel.pendingArchiveGrant?.initials ?? "A"
    }

    private var selectedRole: AccessRole {
        viewModel.selectedRoleForGrantAccess
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

            content

            Spacer(minLength: 0)

            bottomActions
                .background(Color.white)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: {
                    viewModel.closeGrantArchiveAccess()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.blue900)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                Spacer()
            }

            Text("Grant access")
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

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("GRANT ACCESS TO ARCHIVE")

                HStack(spacing: 16) {
                    avatar

                    (
                        Text("The ")
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(Color.blue900)
                        + Text(archiveName)
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(Color.blue900)
                        + Text(" Archive")
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(Color.blue900)
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("ACCESS ROLE")

                Button(action: {
                    viewModel.navigationDirection = .forward
                    viewModel.showRoleSelection = true
                }) {
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

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.blue200)
                    }
                    .padding(.top, 12)
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
                viewModel.closeGrantArchiveAccess()
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
                viewModel.submitGrantArchiveAccess()
            }) {
                Text("Grant access")
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

    private var avatar: some View {
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

                Text(archiveInitials)
                    .font(.custom("Usual-Medium", size: 10))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 32, height: 32)
        .cornerRadius(8)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.custom("Usual-Regular", size: 10))
            .foregroundColor(Color.blue900)
            .tracking(1.6)
            .textCase(.uppercase)
    }
}
