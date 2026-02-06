//
//  SharePreviewView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI

struct SharePreviewView: View {
    @StateObject private var viewModel: SharePreviewSwiftUIViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isDismissing = false
    @State private var animatedShowBanner = false
    @State private var delayedAccessRoleText: String?
    @State private var accessRoleUpdateID = UUID()
    @State private var isBannerTransitioning = false
    @State private var accessRoleWasVisibleBeforeLoad = false
    
    init(shareToken: String,
         onNavigateToFolder: ((NavigateMinParams) -> Void)? = nil,
         onNavigateToShares: ((String) -> Void)? = nil,
         onNavigateToSharedWithMe: ((NavigateMinParams?) -> Void)? = nil,
         onNavigateToSharedByMe: ((NavigateMinParams?) -> Void)? = nil) {
        let vm = SharePreviewSwiftUIViewModel(shareToken: shareToken)
        vm.onNavigateToFolder = onNavigateToFolder
        vm.onNavigateToShares = onNavigateToShares
        vm.onNavigateToSharedWithMe = onNavigateToSharedWithMe
        vm.onNavigateToSharedByMe = onNavigateToSharedByMe
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        mainContent
            .navigationTitle(viewModel.shareName.isEmpty ? "Share Preview" : viewModel.shareName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        handleBackAction()
                    }) {
                        Image("shareLinkBackArrow")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .padding(.leading, -10)
                    }
                }
            }
            .onAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.cancelLoadingTask()
            }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .top) {
            Color.blue25.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Safe area spacer for navigation bar
                Color.clear
                    .frame(height: 0)
                    .frame(maxWidth: .infinity)
                
                SharePreviewHeaderView(
                    shareName: viewModel.shareName,
                    sharedByName: viewModel.sharedByName,
                    archiveName: viewModel.archiveName,
                    thumbnailURL: viewModel.thumbnailURL
                )
                
                ZStack(alignment: .bottom) {
                    ScrollView {
                        SharePreviewGridView(
                            items: viewModel.items,
                            isBlurred: viewModel.displayMode == .blurredPlaceholders
                        )
                            .padding(.top, 16)
                            .padding(.bottom, 200)
                    }
                    .disabled(viewModel.displayMode == .blurredPlaceholders)
                    
                    SharePreviewArchiveSelectorView(
                        currentArchive: viewModel.displayedArchive,
                        availableArchives: viewModel.availableArchives,
                        onSelect: { archive in viewModel.selectArchive(archive) },
                        onViewInArchive: { viewModel.viewInArchive() },
                        externalShowPicker: $viewModel.shouldOpenArchivePicker,
                        buttonTitle: viewModel.buttonTitle,
                        isButtonDisabled: viewModel.isButtonDisabled,
                        showButton: viewModel.hasCompletedInitialLoad,
                        showOriginalArchiveBanner: animatedShowBanner,
                        accessRoleText: delayedAccessRoleText
                    )
                    .onChange(of: viewModel.isOriginalArchiveSelected) { newValue in
                        isBannerTransitioning = true
                        if newValue {
                            scheduleAccessRoleUpdate(nil, delay: 0.0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    animatedShowBanner = true
                                }
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                animatedShowBanner = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                scheduleAccessRoleUpdate(viewModel.accessRoleText, delay: 0.0)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isBannerTransitioning = false
                        }
                    }
                    .onChange(of: viewModel.accessRoleText) { newValue in
                        if viewModel.isLoading && !accessRoleWasVisibleBeforeLoad {
                            return
                        }
                        if isBannerTransitioning {
                            return
                        }
                        let delay: TimeInterval = isBannerTransitioning ? 0.2 : 0.0
                        scheduleAccessRoleUpdate(newValue, delay: delay)
                    }
                    .onChange(of: viewModel.isLoading) { isLoading in
                        if isLoading {
                            accessRoleWasVisibleBeforeLoad = delayedAccessRoleText != nil
                        } else {
                            let delay: TimeInterval = isBannerTransitioning ? 0.2 : 0.0
                            scheduleAccessRoleUpdate(viewModel.accessRoleText, delay: delay)
                            accessRoleWasVisibleBeforeLoad = false
                        }
                    }
                    .onAppear {
                        animatedShowBanner = viewModel.isOriginalArchiveSelected
                        delayedAccessRoleText = viewModel.accessRoleText
                    }
                }
            }
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
            
            // Archive picker overlay using offset-based animation
            pickerOverlay
        }
        .alert(isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? ""),
                primaryButton: .default(Text("Retry"), action: { viewModel.start() }),
                secondaryButton: .cancel(Text("Dismiss"), action: { viewModel.errorMessage = nil })
            )
        }
        .alert(isPresented: $viewModel.showArchiveMismatchAlert) {
            Alert(
                title: Text("Incorrect Archive"),
                message: Text("This item is shared from '\(viewModel.cleanArchiveName ?? viewModel.archiveName)'. You need to select the correct archive to view this content."),
                primaryButton: .default(Text("Change Archive"), action: { viewModel.shouldOpenArchivePicker = true }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private func handleBackAction() {
        guard !isDismissing else { return }
        isDismissing = true
        
        viewModel.restoreInitialArchive {
            self.presentationMode.wrappedValue.dismiss()
        }
    }

    private func scheduleAccessRoleUpdate(_ newValue: String?, delay: TimeInterval) {
        let updateID = UUID()
        accessRoleUpdateID = updateID
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if accessRoleUpdateID == updateID {
                delayedAccessRoleText = newValue
            }
        }
    }
    
    private var pickerOverlay: some View {
        ZStack(alignment: .bottom) {
            // Dimming backdrop
            Color.black
                .opacity(viewModel.shouldOpenArchivePicker ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.shouldOpenArchivePicker = false
                }
                .allowsHitTesting(viewModel.shouldOpenArchivePicker)
            
            // Picker card with offset animation
            VStack {
                Spacer()
                
                ArchivePickerView(
                    archives: viewModel.availableArchives.filter { $0.archiveNbr != nil && !($0.fullName?.isEmpty ?? true) },
                    selectedArchive: viewModel.currentArchive,
                    maxHeight: min(CGFloat(viewModel.availableArchives.filter { $0.archiveNbr != nil && !($0.fullName?.isEmpty ?? true) }.count), 5) * 72,
                    onSelect: { archive in
                        viewModel.shouldOpenArchivePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            viewModel.selectArchive(archive)
                        }
                    },
                    onClose: {
                        viewModel.shouldOpenArchivePicker = false
                    }
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(radius: 10)
                .offset(y: viewModel.shouldOpenArchivePicker ? 0 : 500)
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.shouldOpenArchivePicker)
    }
}

struct SharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SharePreviewView(shareToken: "mock")
        }
    }
}
