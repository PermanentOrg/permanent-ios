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
            // Top bar
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(height: 64)
                .background(Color.white)
            
            // Content with ScrollView
            ScrollView {
                VStack(spacing: 0) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                        .background(Color.blue50)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(AccessRole.allCases.filter { $0 != .curator }, id: \.self) { role in
                            SelectableOptionView(
                                option: role,
                                isSelected: viewModel.selectedAccessRole == role,
                                action: {
                                    viewModel.updateAccessRole(role)
                                }
                            )
                        }
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
                Spacer()
            }
            
            Text("Select access role")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)
            
            HStack {
                Spacer()
                Button(action: { 
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
        .frame(height: 32)
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
}
