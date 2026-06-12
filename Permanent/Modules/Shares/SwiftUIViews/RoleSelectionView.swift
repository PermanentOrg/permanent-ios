//
//  RoleSelectionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.09.2025.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    
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
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach([AccessRole.viewer, .contributor, .editor, .curator, .owner], id: \.self) { role in
                        SelectableOptionView(
                            option: role,
                            isSelected: isRoleSelected(role),
                            action: {
                                handleRoleSelection(role)
                            }
                        )
                    }
                }
            }
        }
        .background(Color.white)
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
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
                        viewModel.navigationDirection = .backward
                        viewModel.showRoleSelection = false
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
                        viewModel.navigationDirection = .backward
                        viewModel.showRoleSelection = false
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
            
            Text("Select access role")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)
            
            HStack {
                Spacer()
                if #available(iOS 26.0, *) {
                    Button(action: {
                        viewModel.revertChanges()
                        viewModel.navigationDirection = .backward
                        viewModel.showRoleSelection = false
                        viewModel.showLinkSettings = false
                    }) {
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
                    Button(action: {
                        viewModel.revertChanges()
                        viewModel.navigationDirection = .backward
                        viewModel.showRoleSelection = false
                        viewModel.showLinkSettings = false
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
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Updating role...")
                        .foregroundColor(.white)
                        .font(.body)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            )
            .ignoresSafeArea()
    }
    
    private func isRoleSelected(_ role: AccessRole) -> Bool {
        if viewModel.showEditInvitation {
            return viewModel.selectedRoleForEditInvitation == role
        } else if viewModel.showArchiveAccessManagement {
            return viewModel.selectedRoleForArchive == role
        } else if viewModel.showInviteAndGrantAccess {
            return viewModel.selectedRoleForInviteAccess == role
        } else if viewModel.showGrantArchiveAccess {
            return viewModel.selectedRoleForGrantAccess == role
        } else {
            return viewModel.selectedAccessRole == role
        }
    }

    private func handleRoleSelection(_ role: AccessRole) {
        if viewModel.showEditInvitation {
            viewModel.selectedRoleForEditInvitation = role
            viewModel.navigationDirection = .backward
            viewModel.showRoleSelection = false
        } else if viewModel.showArchiveAccessManagement {
            viewModel.selectedRoleForArchive = role
            viewModel.navigationDirection = .backward
            viewModel.showRoleSelection = false
        } else if viewModel.showInviteAndGrantAccess {
            viewModel.selectedRoleForInviteAccess = role
            viewModel.navigationDirection = .backward
            viewModel.showRoleSelection = false
        } else if viewModel.showGrantArchiveAccess {
            viewModel.selectedRoleForGrantAccess = role
            viewModel.navigationDirection = .backward
            viewModel.showRoleSelection = false
        } else {
            viewModel.updateAccessRole(role)
        }
    }
}
