//
//  ArchiveAccessManagementView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2025.
//

import SwiftUI

struct ArchiveAccessManagementView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @State private var revokeArchiveName: String = ""
    @State private var archiveName: String = ""
    @State private var archiveThumbnailURL: String?
    
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
                VStack(spacing: 24) {
                    // Grant Access to Archive Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("GRANT ACCESS TO ARCHIVE")
                            .font(.custom("Usual-Regular", size: 10))
                            .kerning(1.6)
                            .foregroundColor(Color.blue900)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Archive info row
                        HStack(spacing: 12) {
                            Group {
                                if let thumbURL = archiveThumbnailURL,
                                   let url = URL(string: thumbURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(.shareArchivePending)
                                    }
                                } else {
                                    Image(.shareArchivePending)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("The") +
                                    Text(" \(archiveName) ")
                                        .bold() +
                                    Text("Archive")
                                }
                                .font(.custom("Usual", size: 14))
                                .foregroundColor(Color.blue900)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Access Role Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCESS ROLE")
                            .font(.custom("Usual-Regular", size: 10))
                            .kerning(1.6)
                            .foregroundColor(Color.blue900)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Current role row
                        Button(action: {
                            // Navigate to role selection
                            viewModel.navigationDirection = .forward
                            viewModel.showRoleSelection = true
                        }) {
                            HStack(spacing: 16) {
                                // Role icon
                                let currentRole = getCurrentRole()
                                currentRole.icon
                                    .renderingMode(.template)
                                    .foregroundColor(Color.blue900)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .background(Color.blue25)
                                    .cornerRadius(4)
                                
                                Text(currentRole.title)
                                    .font(.custom("Usual-Medium", size: 14))
                                    .foregroundColor(Color.blue900)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.blue200)
                            }
                            .padding(.top, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    Rectangle()
                      .foregroundColor(.clear)
                      .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                      .background(Color.blue50)
                      .padding(.horizontal, 24)
                    
                    // Revoke Access Section
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            revokeArchiveName = archiveName

                            DispatchQueue.main.async {
                                viewModel.showRevokeArchiveAccessAlert = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(.publishRevokeLink2)
                                    .renderingMode(.template)
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.red)
                                
                                Text("Revoke access")
                                    .font(.custom("Usual", size: 14))
                                    .foregroundColor(Color.error500)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            
            // Bottom buttons
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
                    }) {
                        Text("Cancel")
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(Color.blue900)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue25)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save")
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(hasChanges() ? Color.blue900 : Color.blue200)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!hasChanges())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
        .onAppear {
            // Initialize selectedRoleForArchive with the original role from the currently selected archive
            if viewModel.selectedRoleForArchive == nil {
                guard let selectedArchive = viewModel.selectedArchiveForEdit else { return }
                viewModel.selectedRoleForArchive = AccessRole.roleForValue(selectedArchive.accessRole ?? "viewer")
            }
            
            if let selectedArchive = viewModel.selectedArchiveForEdit {
                let archiveVO = selectedArchive.archiveVO ?? {
                    if let archiveID = selectedArchive.archiveID {
                        return viewModel.sharedArchives.first { $0.archiveID == archiveID }?.archiveVO
                    }
                    return nil
                }()
                archiveName = archiveVO?.fullName ?? "Unknown Archive"
                archiveThumbnailURL = archiveVO?.preferredThumbnailURL
            }
        }
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
        .overlay {
            RevokeBottomAlertView(
                isPresented: $viewModel.showRevokeArchiveAccessAlert,
                title: "Are you sure you want to revoke access from The \(viewModel.selectedArchiveForEdit?.archiveVO?.fullName ?? "Archive") Archive? This action will immediately remove all permissions granted.",
                buttonText: "Revoke access",
                onRevoke: {
                    revokeAccess()
                },
                titleView: {
                    AnyView(
                        Group {
                            Text("Are you sure you want to revoke access from ")
                            + Text("The \(revokeArchiveName) Archive").fontWeight(.semibold)
                            + Text("? This action will immediately remove all permissions granted.")
                        }
                    )
                }
            )
        }
    }
    
    private var topBar: some View {
        ZStack {
            HStack {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
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
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
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
            
            Text("Edit Archive access")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)
            
            HStack {
                Spacer()
                if #available(iOS 26.0, *) {
                    Button(action: {
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
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
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
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
    
    private func getCurrentRole() -> AccessRole {
        // Prioritize the selected role for archive (user's selection)
        if let selectedRole = viewModel.selectedRoleForArchive {
            return selectedRole
        }
        
        // Fallback to the original role from the archive
        guard let selectedArchive = viewModel.selectedArchiveForEdit else { return .viewer }
        return AccessRole.roleForValue(selectedArchive.accessRole ?? "viewer")
    }
    
    private func hasChanges() -> Bool {
        guard let selectedArchive = viewModel.selectedArchiveForEdit,
              let newRole = viewModel.selectedRoleForArchive else { 
            return false
        }
        
        let originalRole = AccessRole.roleForValue(selectedArchive.accessRole ?? "viewer")
        return originalRole != newRole
    }
    
    private func archiveDisplayName(shareVO: ShareVOData) -> String {
        // Extract archive name from shareVO
        if let archiveVO = shareVO.archiveVO, let fullName = archiveVO.fullName {
            return fullName
        }
        
        // Fallback to checking other shared archives for the same archiveID
        if let archiveID = shareVO.archiveID {
            for otherShare in viewModel.sharedArchives {
                if otherShare.archiveID == archiveID, let fullName = otherShare.archiveVO?.fullName {
                    return fullName
                }
            }
        }
        
        return "Unknown Archive"
    }
    
    private func revokeAccess() {
        guard let selectedArchive = viewModel.selectedArchiveForEdit else { return }
        
        // Call the API to revoke access
        viewModel.revokeArchiveAccess(shareVO: selectedArchive) { [weak viewModel] result, errorMessage in
            DispatchQueue.main.async {
                guard let viewModel = viewModel else { return }
                
                switch result {
                case .success:
                    // Navigate back after successful revoke
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
                    }
                    
                case .error:
                    // The error message is already set in the viewModel by revokeArchiveAccess
                    // The loading state is also cleared there
                    break
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let selectedArchive = viewModel.selectedArchiveForEdit,
              let newRole = viewModel.selectedRoleForArchive else { 
            // No changes to save, just go back
            viewModel.navigationDirection = .backward
            viewModel.showArchiveAccessManagement = false
            return 
        }
        
        // Only save if role has changed
        let originalRole = AccessRole.roleForValue(selectedArchive.accessRole ?? "viewer")
        if originalRole == newRole {
            // No changes, just go back
            viewModel.selectedRoleForArchive = nil
            viewModel.navigationDirection = .backward
            viewModel.showArchiveAccessManagement = false
            return
        }
        
        // Call the API to update the archive access role
        viewModel.updateArchiveAccessRole(shareVO: selectedArchive, newRole: newRole) { [weak viewModel] result, errorMessage in
            DispatchQueue.main.async {
                guard let viewModel = viewModel else { return }
                
                switch result {
                case .success:
                    // Navigate back after successful update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.selectedRoleForArchive = nil
                        viewModel.navigationDirection = .backward
                        viewModel.showArchiveAccessManagement = false
                    }
                    
                case .error:
                    // The error message is already set in the viewModel by updateArchiveAccessRole
                    // The loading state is also cleared there
                    break
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
                    
                    Text("Saving changes...")
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
