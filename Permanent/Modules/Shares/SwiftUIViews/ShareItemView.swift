//
//  ShareItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI

struct ShareItemView: View {
    @StateObject private var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(fileModel: FileModel) {
        self._viewModel = StateObject(wrappedValue: ShareItemViewModel(fileModel: fileModel))
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Top bar + tinted header area
                VStack(spacing: 0) {
                    ZStack {
                        topBar
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                    }
                    .frame(height: 64)
                    .background(Color.white)
                    
                    VStack(spacing: 20) {
                        fileInfoSection
                        
                        Group {
                            if viewModel.genLinkLoading {
                                linkCreationLoadingSection
                                    .transition(.opacity.combined(with: .scale))
                            } else if !viewModel.hasShareLink && !viewModel.isLoading {
                                createLinkSection
                                    .transition(.opacity.combined(with: .scale))
                            } else if viewModel.hasShareLink {
                                shareLinkSection
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.genLinkLoading)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.hasShareLink)
                    }
                    .padding(24)
                }
                Spacer()
            }
        .background(Color.blue25)
        .overlay {
            if viewModel.isLoading && !viewModel.genLinkLoading {
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
            Text("Share item")
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
    
    // MARK: - File Info Section
    private var fileInfoSection: some View {
        HStack(spacing: 16) {
            Group {
                if let urlString = viewModel.thumbnailURL, let url = URL(string: urlString), !viewModel.isFolder {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.3))
                            .overlay(Image(systemName: "doc.fill").foregroundColor(.white.opacity(0.7)))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.3))
                        .overlay(Image(.folderThumbnailV1))
                }
            }
            .layoutPriority(1)
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // File Details
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.fileName)
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue900)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if !viewModel.fileSize.isEmpty {
                        Text(viewModel.fileSize)
                            .font(.custom("Usual-Regular", size: 12))
                            .foregroundColor(Color.blue400)
                    }
                    
                    if !viewModel.fileSize.isEmpty && !viewModel.shareDisplayData.isEmpty {
                        Text("•")
                            .font(.custom("Usual-Regular", size: 12))
                            .foregroundColor(Color.blue400)
                    }
                    
                    Text(viewModel.shareDisplayData)
                        .font(.custom("Usual-Regular", size: 12))
                        .foregroundColor(Color.blue400)
                }
            }
            .layoutPriority(1)
            Spacer()
        }
    }
    
    // MARK: - Link Creation Loading Section
    private var linkCreationLoadingSection: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .center) {
                GradientSemiCirclesLoaderView(innerCicleWidth: 2, innerCicleSize: 7, outerCicleWidth: 2,frameWidth: 16, frameHeight:16)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)
            .layoutPriority(1)
            
            HStack(spacing: 0) {
                AnimatedTextWithDotsView()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Create Link Section (card row)
    private var createLinkSection: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .center) {
                Image(.sharePublishGetLink)
                    .foregroundColor(Color.blue900)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)
            .layoutPriority(1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Create link to share")
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue900)
                Text("Generate a link to send via text or email to invite people to share this content.")
                    .layoutPriority(1)
                    .font(.custom("Usual-Regular", size: 12))
                    .lineSpacing(3)
                    .foregroundColor(Color.blue600)
            }
            
            Spacer()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture { viewModel.createShareLink() }
        .opacity(viewModel.genLinkLoading ? 0.6 : 1.0)
        .disabled(viewModel.genLinkLoading)
    }
    
    // MARK: - Share Link Section
    private var shareLinkSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Thumbnail with gradient
            VStack(alignment: .center) {
                Image(.sharePublishGetLink)
                    .renderingMode(.template)
                    .foregroundStyle(Gradient.purpleYellowGradientForText)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .frame(width: 32, height: 32)
            .background(Color.blue25)
            .cornerRadius(4)
            
            // Content section
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
                            .frame(width: 24, height: 24)
                        
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
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    if viewModel.isCreatingLink {
                        Text("Creating share link...")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            )
            .ignoresSafeArea()
    }
}

// MARK: - Animated Text with Dots View
struct AnimatedTextWithDotsView: View {
    @State private var dotCount = 0
    
    var body: some View {
        Text("Creating link" + String(repeating: ".", count: dotCount))
            .font(.custom("Usual-Regular", size: 14))
            .foregroundStyle(Gradient.purpleYellowGradientForText)
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotCount = (dotCount + 1) % 4 // 0, 1, 2, 3, then back to 0
            }
        }
    }
}
