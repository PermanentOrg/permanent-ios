//
//  ShareItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI

struct ShareItemView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var denyConfirmationTitle: String = "Are you sure you want to deny access?"
    @State private var denyArchiveName: String = ""
    
    init(viewModel: ShareItemViewModel) {
        self.viewModel = viewModel
    }
    
    // Alternative initializer for backwards compatibility
    init(fileModel: FileModel) {
        self.viewModel = ShareItemViewModel(fileModel: fileModel)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .frame(height: 64)
                .background(Color.white)
                
                VStack(spacing: 0) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                        .background(Color.blue50)
                    
                    VStack(spacing: 20) {
                        fileInfoSection
                        
                        Group {
                            if viewModel.genLinkLoading {
                                linkCreationLoadingSection
                                    .transition(.opacity.combined(with: .scale))
                            } else if viewModel.shouldShowCreateButton {
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
                        .animation(.easeInOut(duration: 0.3), value: viewModel.shouldShowCreateButton)
                    }
                    .padding(24)
                    
                    shareManagementSections
                }
                .background(Color.blue25)
            }
            .background(Color.blue25)
            .overlay {
                if (viewModel.isLoading && !viewModel.genLinkLoading) || viewModel.isLoadingArchives {
                    loadingOverlay
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage { Text(errorMessage) }
            }
            
            RevokeBottomAlertView(
                isPresented: $viewModel.showDenyArchiveAccessAlert,
                title: denyConfirmationTitle,
                buttonText: "Deny access",
                onRevoke: {
                    if let shareVO = viewModel.selectedArchiveForDeny {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            viewModel.denyShareRequest(shareVO)
                        }
                        viewModel.selectedArchiveForDeny = nil
                        denyConfirmationTitle = ""
                        denyArchiveName = ""
                    }
                },
                onCancel: {
                    viewModel.selectedArchiveForDeny = nil
                    denyConfirmationTitle = ""
                    denyArchiveName = ""
                },
                titleView: {
                    AnyView(
                        Group {
                            Text("Are you sure you want to deny access from ")
                            + Text("The \(denyArchiveName) Archive").fontWeight(.semibold)
                            + Text("?")
                        }
                    )
                }
            )
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
        .onTapGesture { viewModel.createShareLinkV2() }
        .opacity(viewModel.genLinkLoading ? 0.6 : 1.0)
        .disabled(viewModel.genLinkLoading)
    }
    
    // MARK: - Share Link Section
    private var shareLinkSection: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center) {
                Image(.publishLock)
                    .renderingMode(.template)
                    .foregroundColor(Color.success500)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .frame(width: 32, height: 32)
            .background(Color.success50)
            .cornerRadius(4)
            
            HStack(alignment: .center, spacing: 16) {
                    if let shareLink = viewModel.shareLink {
                        Text(shareLink.replacingOccurrences(of: "https://", with: ""))
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundStyle(Gradient.purpleYellowGradientForText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                HStack(spacing: 8) {
                    Button(action: { 
                        viewModel.navigationDirection = .forward
                        viewModel.showLinkSettings = true 
                    }) {
                        Image(.publishGear)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.blue900)
                        
                    }
                    
                    Button(action: { viewModel.copyLink() }) {
                        Image(.shareCopyV2)
                            .resizable()
                            .frame(width: 24, height: 24)
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
    
    // MARK: - Share Management Sections
    private var shareManagementSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            grantAccessToOtherArchivesSection

            if viewModel.shouldShowArchivesSection {
                Text("CURRENT REQUESTS AND ACCESS:")
                    .font(.custom("Usual", size: 11))
                    .foregroundColor(Color.blue900)
                    .textCase(.uppercase)
                    .kerning(1.6)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 24)
                    .background(Color.white)

                Group {
                    if #available(iOS 16.4, *) {
                        ScrollView(showsIndicators: false) {
                            scrollableContent
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                        .background(Color.white)
                    } else {
                        ScrollView(showsIndicators: false) {
                            scrollableContent
                        }
                        .background(Color.white)
                    }
                }
            } else {
                Spacer(minLength: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private var grantAccessToOtherArchivesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GRANT ACCESS TO OTHER ARCHIVES")
                .font(.custom("Usual", size: 11))
                .foregroundColor(Color.blue900)
                .textCase(.uppercase)
                .kerning(1.6)
                .padding(.bottom, 2)

            grantAccessRow(
                systemIcon: "magnifyingglass",
                title: "Find an archive using email address",
                action: {
                    viewModel.openFindArchiveByEmail()
                }
            )

            grantAccessRow(
                systemIcon: "archivebox",
                title: "Select an archive from past shares",
                action: {
                    viewModel.openSelectArchiveFromPastShares()
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .background(Color.white)
    }

    private func grantAccessRow(systemIcon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                        stops: [
                        Gradient.Stop(color: Color(red: 0.07, green: 0.11, blue: 0.29), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.21, green: 0.27, blue: 0.57), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                        )
                    )
                    .cornerRadius(6)

                Text(title)
                    .font(.custom("Usual-Medium", size: 14))
                    .foregroundColor(Color.blue900)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.blue200)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var scrollableContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isLoadingArchives {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue900))
                    
                    Text("Loading shared archives...")
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundColor(Color.blue600)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.sharedArchives.indices, id: \.self) { index in
                    let shareVO = viewModel.sharedArchives[index]
                    archiveAccessRow(shareVO: shareVO)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Archive Access Row
    private func archiveAccessRow(shareVO: ShareVOData) -> some View {
        HStack(spacing: 12) {
            // Check if this is a pending request or approved archive
            let isPending = shareVO.status?.contains("pending") == true
            
            if isPending {
                userAvatarView(shareVO: shareVO)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(archiveDisplayName(shareVO: shareVO))
                        .font(.custom("Usual-Medium", size: 14))
                        .foregroundColor(Color.blue900)
                        .lineLimit(1)
                    
                    Text("Pending...")
                        .font(.custom("Usual-Regular", size: 12))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    let shareID = shareVO.shareID ?? -1
                    let isApproving = viewModel.isApprovingShare(shareID: shareID)
                    let isDenying = viewModel.isDenyingShare(shareID: shareID)
                    let isProcessing = isApproving || isDenying
                    
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .frame(width: 24, height: 24)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale(scale: 0.1).combined(with: .opacity)
                                ))
                        } else {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.approveShareRequest(shareVO)
                                }
                            }) {
                                Image(.shareApprove)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale(scale: 0.1).combined(with: .opacity)
                                    ))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Capture the archive name before showing the alert
                                let archiveName = shareVO.archiveVO?.fullName ?? "Archive"
                                denyConfirmationTitle = "Are you sure you want to deny access from The \(archiveName) Archive?"
                                denyArchiveName = archiveName
                                viewModel.selectedArchiveForDeny = shareVO
                                
                                // Delay showing the alert to ensure the title is set first
                                DispatchQueue.main.async {
                                    viewModel.showDenyArchiveAccessAlert = true
                                }
                            }) {
                                Image(.shareDeny)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale(scale: 0.1).combined(with: .opacity)
                                    ))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            } else {
                archiveThumbnailView(shareVO: shareVO)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(archiveDisplayName(shareVO: shareVO))
                        .font(.custom("Usual-Medium", size: 14))
                        .foregroundColor(Color.blue900)
                        .lineLimit(1)
                    
                    let role = accessRoleFromShareVO(shareVO)
                    HStack(spacing: 4) {
                        Text(role.title.uppercased())
                            .font(.custom("Usual-Regular", size: 10))
                            .kerning(1.2)
                            .foregroundColor(Color.blue900)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue25)
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.selectedArchiveForEdit = shareVO
                    viewModel.navigationDirection = .forward
                    viewModel.showArchiveAccessManagement = true
                }) {
                    Image(.shareArchiveEditShare)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Views
    private func userAvatarView(shareVO: ShareVOData) -> some View {
        return ZStack {
            Image(.shareArchivePending)
                .cornerRadius(8)
        }
        .frame(width: 40, height: 40)
    }
    
    private func archiveThumbnailView(shareVO: ShareVOData) -> some View {
        let archiveVO = shareVO.archiveVO ?? {
            if let archiveID = shareVO.archiveID {
                return viewModel.sharedArchives.first { $0.archiveID == archiveID }?.archiveVO
            }
            return nil
        }()
        
        return Group {
            // Try all available thumbnail URLs in order of preference
            if let thumbURL = archiveVO?.thumbURL2000 ?? archiveVO?.thumbURL1000 ?? archiveVO?.thumbURL500 ?? archiveVO?.thumbURL200,
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
    }
    
    private func archiveDisplayName(shareVO: ShareVOData) -> String {
        if let fullName = shareVO.archiveVO?.fullName {
            return "The \(fullName) Archive"
        }
        
        if let archiveID = shareVO.archiveID {
            for otherShare in viewModel.sharedArchives {
                if otherShare.archiveID == archiveID, let fullName = otherShare.archiveVO?.fullName {
                    return "The \(fullName) Archive"
                }
            }
        }
        
        if shareVO.status?.contains("pending") != true {
            return "Loading archive info..."
        }
        
        return "Unknown Archive"
    }
    
    private func accessRoleDisplayText(shareVO: ShareVOData) -> String {
        let accessRole = shareVO.accessRole ?? "viewer"
        switch accessRole.lowercased() {
        case "access.role.viewer", "viewer":
            return "viewer"
        case "access.role.contributor", "contributor":
            return "contributor"
        case "access.role.editor", "editor":
            return "editor"
        case "access.role.curator", "curator":
            return "curator"
        case "access.role.manager", "manager":
            return "manager"
        case "access.role.owner", "owner":
            return "owner"
        default:
            return "viewer"
        }
    }
    
    private func accessRoleFromShareVO(_ shareVO: ShareVOData) -> AccessRole {
        let accessRole = shareVO.accessRole ?? "viewer"
        let role = AccessRole.roleForValue(accessRole)
        // For file sharing, display curator when backend returns manager
        return role == .manager ? .curator : role
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
