//
//  LinkSettingsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2025.
//

import SwiftUI

struct LinkSettingsView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Top bar
                ZStack {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .frame(height: 64)
                .background(Color.white)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                            .background(Color.blue50)
                        
                        VStack(spacing: 20) {
                            linkDisplaySection
                            
                            generalAccessSection
                            
                            linkExpirationSection
                            
                            separator
                            
                            revokeLinkButton
                        }
                        .padding(.bottom, 120) // Height of buttons + padding + safe area
                    }
                }
            }

            VStack {
                Spacer()
                Rectangle()
                    .fill(.regularMaterial)
                    .frame(height: 150)
                    .mask {
                        LinearGradient(colors: [Color.black, Color.black, Color.black, Color.black.opacity(0)], startPoint: .bottom, endPoint: .top)
                    }
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Floating buttons at bottom with proper background
            HStack(spacing: 24) {
                cancelButton
                doneButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
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
    
    // MARK: - Top Bar
    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: { 
                    viewModel.navigationDirection = .backward
                    viewModel.showLinkSettings = false 
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.blue900)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            
            Text("Link settings")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)
            
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(.closeButtonV2)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(height: 32)
    }
    
    // MARK: - Link Display Section
    private var linkDisplaySection: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center) {
                Image(.sharePublishGetLink)
                    .renderingMode(.template)
                    .foregroundStyle(Gradient.purpleYellowGradientForText)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 32, height: 32)
            .background(Color.blue25)
            .cornerRadius(4)
            
            HStack(alignment: .center, spacing: 8) {
                if let shareLink = viewModel.shareLink {
                    Text(shareLink.replacingOccurrences(of: "https://", with: ""))
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundStyle(Gradient.purpleYellowGradientForText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Button(action: { viewModel.copyLink() }) {
                    HStack(spacing: 8) {
                        Image(.shareCopyV2)
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Copy")
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(Color.blue900)
                    }
                }
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color(red: 0.91, green: 0.91, blue: 0.93), lineWidth: 1)
        )
        .padding(.vertical, 24)
        .padding(.leading, 20)
        .padding(.trailing, 24)
        .background(Color.blue25)
    }
    
    // MARK: - General Access Section
    private var generalAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GENERAL ACCESS")
                .font(.custom("Usual-Regular", size: 10))
                .kerning(1.6)
                .foregroundColor(Color.blue900)
                .textCase(.uppercase)
            
            HStack(spacing: 16) {
                Group {
                    viewModel.selectedAccessLevel.icon
                        .frame(width: 16, height: 16)
                        .foregroundColor(viewModel.selectedAccessLevel.iconColor)
                        .padding(10)
                        .background(viewModel.selectedAccessLevel.iconColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(viewModel.selectedAccessLevel.title)
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue900)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.blue200)
            }
            .onTapGesture {
                viewModel.navigationDirection = .forward
                viewModel.showGeneralAccess = true
            }
            
            // Show additional options when Restricted is selected
            if viewModel.selectedAccessLevel == .restricted {
                
                // Default Access Role Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DEFAULT ACCESS ROLE")
                        .font(.custom("Usual-Regular", size: 10))
                        .kerning(1.6)
                        .foregroundColor(Color.blue900)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 16) {
                        Group {
                            viewModel.selectedAccessRole.icon
                                .frame(width: 16, height: 16)
                                .foregroundColor(viewModel.selectedAccessRole.iconColor)
                                .padding(10)
                                .background(viewModel.selectedAccessRole.iconColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Text(viewModel.selectedAccessRole.title)
                            .font(.custom("Usual-Medium", size: 14))
                            .foregroundColor(Color.blue900)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.blue200)
                    }
                    .onTapGesture {
                        viewModel.navigationDirection = .forward
                        viewModel.showRoleSelection = true
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Link Expiration Section
    private var linkExpirationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LINK EXPIRATION")
                .font(.custom("Usual-Regular", size: 10))
                .kerning(1.6)
                .foregroundColor(Color.blue900)
                .textCase(.uppercase)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(Array(ShareExpirationOption.allCases.filter { $0 != .none }.prefix(2)), id: \.self) { option in
                        ExpirationOptionView(
                            icon: option.icon,
                            title: option.title,
                            isSelected: viewModel.selectedExpiration == option,
                            action: {
                                viewModel.updateExpiration(option)
                            }
                        )
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(Array(ShareExpirationOption.allCases.filter { $0 != .none }.dropFirst(2)), id: \.self) { option in
                        ExpirationOptionView(
                            icon: option.icon,
                            title: option.title,
                            isSelected: viewModel.selectedExpiration == option,
                            action: {
                                viewModel.updateExpiration(option)
                            }
                        )
                    }
                }
            }
            
            HStack(spacing: 16) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 16, height: 16)
                
                Text(viewModel.expirationDisplayText)
                    .font(.custom("Usual-Regular", size: 12))
                    .foregroundColor(Color.warning800)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(red: 1.0, green: 0.95, blue: 0.85))
            .cornerRadius(12)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 1, green: 0.94, blue: 0.78))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var separator: some View {
        Rectangle()
        .foregroundColor(.clear)
        .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
        .background(Color.blue50)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Revoke Link Button
    private var revokeLinkButton: some View {
        Button(action: { viewModel.revokeLink() }) {
            HStack(spacing: 16) {
                Image(.publishRevokeLink)
                    .renderingMode(.template)
                    .foregroundColor(.error500)
                    .frame(width: 16, height: 16)
                
                Text("Revoke link")
                    .font(.custom("Usual", size: 14))
                    .foregroundColor(.error500)
            }
            .padding(.horizontal, 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Done Button
    private var doneButton: some View {
        Button(action: { 
            if viewModel.hasUnsavedChanges {
                viewModel.saveChanges()
            } else {
                viewModel.navigationDirection = .backward
                viewModel.showLinkSettings = false
            }
        }) {
            Text(viewModel.hasUnsavedChanges ? "Save" : "Done")
                .font(.custom("Usual-Medium", size: 14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.blue900)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button(action: {
                viewModel.navigationDirection = .backward
                viewModel.showLinkSettings = false
        }) {
            Text("Cancel")
                .font(.custom("Usual-Medium", size: 14))
                .foregroundColor(Color.blue900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.blue50)
                .cornerRadius(12)
        }
    }

    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Updating settings...")
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
