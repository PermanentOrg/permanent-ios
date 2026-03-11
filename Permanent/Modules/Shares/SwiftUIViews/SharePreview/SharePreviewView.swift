//
//  SharePreviewView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI
import UIKit

struct SharePreviewView: View {
    private enum ArchiveTypeNavigationDirection {
        case forward
        case backward
    }

    @StateObject private var viewModel: SharePreviewSwiftUIViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isDismissing = false
    @State private var animatedShowBanner = false
    @State private var delayedAccessRoleText: String?
    @State private var accessRoleUpdateID = UUID()
    @State private var isBannerTransitioning = false
    @State private var accessRoleWasVisibleBeforeLoad = false
    @State private var showCreateArchiveSheet = false
    @State private var showArchiveTypeSelection = false
    @State private var archiveTypeNavigationDirection: ArchiveTypeNavigationDirection = .forward
    @State private var newArchiveName = ""
    @State private var selectedArchiveType: ArchiveType = .person
    @State private var isKeyboardVisible = false
    @FocusState private var isArchiveNameFieldFocused: Bool
    
    init(shareToken: String,
         onNavigateToFolder: ((NavigateMinParams) -> Void)? = nil,
         onNavigateToShares: ((String) -> Void)? = nil,
         onNavigateToSharedWithMe: ((NavigateMinParams?) -> Void)? = nil,
         onNavigateToSharedByMe: ((NavigateMinParams?) -> Void)? = nil,
         onNavigateToFilePreview: ((FilePreviewParams) -> Void)? = nil) {
        let vm = SharePreviewSwiftUIViewModel(shareToken: shareToken)
        vm.onNavigateToFolder = onNavigateToFolder
        vm.onNavigateToShares = onNavigateToShares
        vm.onNavigateToSharedWithMe = onNavigateToSharedWithMe
        vm.onNavigateToSharedByMe = onNavigateToSharedByMe
        vm.onNavigateToFilePreview = onNavigateToFilePreview
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
                    .scrollDisabled(true)
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
            
            pickerOverlay
            createArchiveOverlay
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
        .onChange(of: showCreateArchiveSheet) { isVisible in
            if !isVisible {
                isArchiveNameFieldFocused = false
                isKeyboardVisible = false
                showArchiveTypeSelection = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.22)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.22)) {
                isKeyboardVisible = false
            }
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
                    maxHeight: min(CGFloat(viewModel.availableArchives.filter { $0.archiveNbr != nil && !($0.fullName?.isEmpty ?? true) }.count + 1), 6) * 72,
                    onSelect: { archive in
                        viewModel.shouldOpenArchivePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            viewModel.selectArchive(archive)
                        }
                    },
                    onCreateArchive: {
                        viewModel.shouldOpenArchivePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            resetCreateArchiveForm()
                            showCreateArchiveSheet = true
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
    
    private var createArchiveOverlay: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(showCreateArchiveSheet ? 0.35 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(showCreateArchiveSheet)
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        createArchiveHeader
                        
                        ZStack {
                            if showArchiveTypeSelection {
                                archiveTypeSelectionScreen
                                    .transition(archiveTypeScreenTransition)
                            } else {
                                createArchiveDetailsScreen
                                    .transition(archiveTypeScreenTransition)
                            }
                        }
                        .animation(.easeInOut(duration: 0.28), value: showArchiveTypeSelection)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .onTapGesture {
                        dismissKeyboard()
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
                    .ignoresSafeArea(edges: .bottom)
                    .padding(.top, 12)
                    .offset(y: showCreateArchiveSheet ? 20 : UIScreen.main.bounds.height + 100)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showCreateArchiveSheet)
    }

    private var createArchiveHeader: some View {
        HStack {
            Spacer()

            Text(showArchiveTypeSelection ? "Archive type".localized() : "Create archive".localized())
                .font(.custom("Usual", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.blue900)

            Spacer()
        }
        .overlay(alignment: .leading) {
            if showArchiveTypeSelection {
                Button(action: {
                    archiveTypeNavigationDirection = .backward
                    withAnimation(.easeInOut(duration: 0.28)) {
                        showArchiveTypeSelection = false
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.custom("Usual", size: 17))
                        .foregroundColor(.blue900)
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 20)
            }
        }
        .overlay(alignment: .trailing) {
            Button(action: {
                showCreateArchiveSheet = false
            }) {
                Image(systemName: "xmark")
                    .font(.custom("Usual", size: 17))
                    .foregroundColor(.blue200)
                    .frame(width: 24, height: 24)
            }
            .padding(.trailing, 20)
        }
        .frame(height: 64)
        .background(Color.white)
    }

    private var createArchiveDetailsScreen: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("What would you like your first archive to focus on?".localized())
                                .font(.custom("Usual-Light", size: 24))
                                .foregroundColor(.blue900)
                                .lineSpacing(1.2)
                                .fixedSize(horizontal: false, vertical: true)

                            Button(action: {
                                openArchiveTypeSelection()
                            }) {
                                HStack(alignment: .center, spacing: 16) {
                                    selectedArchiveType.onboardingDescriptionIcon
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(8)
                                        .background(Color.blue25)
                                        .cornerRadius(4)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .frame(width: 32, height: 32)

                                    Text(selectedArchiveType.onboardingType)
                                        .font(.custom("Usual", size: 14))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue900)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.custom("Usual", size: 12))
                                        .foregroundColor(.blue200)
                                }
                                .padding(.leading, 8)
                                .padding(.trailing, 12)
                                .frame(height: 48)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .inset(by: 0.5)
                                        .stroke(Color.blue50, lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(ArchiveTypeOpenButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                        .background(Color.blue25)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("NAME YOUR NEW ARCHIVE".localized())
                                .font(.custom("Usual", size: 10))
                                .foregroundColor(.blue600)
                                .kerning(1.6)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 16) {
                                Image("SharePreviewArchiveNotselected")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                HStack(spacing: 8) {
                                    Text("The")
                                        .font(.custom("Usual", size: 14))
                                        .foregroundColor(.blue900)
                                    
                                    TextField(
                                        "",
                                        text: $newArchiveName,
                                        prompt: Text(selectedArchiveType.onboardingType)
                                            .foregroundColor(.blue300)
                                    )
                                    .font(.custom("Usual", size: 14))
                                    .foregroundColor(.blue900)
                                    .textInputAutocapitalization(.words)
                                    .focused($isArchiveNameFieldFocused)
                                }
                                
                                Text("Archive")
                                    .font(.custom("Usual", size: 14))
                                    .foregroundColor(.blue900)
                            }
                            .padding(.leading, 8)
                            .padding(.trailing, 16)
                            .frame(height: 48)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(Color.blue50, lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .id("archiveNameField")
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.top, 0)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: .infinity, alignment: .top)

                if !isKeyboardVisible {
                    VStack(spacing: 12) {
                        Button(action: {
                            createArchiveAction()
                        }) {
                            Text("Create".localized())
                                .font(.custom("Usual", size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue900)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            showCreateArchiveSheet = false
                        }) {
                            Text("Cancel".localized())
                                .font(.custom("Usual", size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue900)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue50)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: isKeyboardVisible)
            .onChange(of: isArchiveNameFieldFocused) { focused in
                guard focused else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollProxy.scrollTo("archiveNameField", anchor: .center)
                    }
                }
            }
        }
    }

    private var archiveTypeSelectionScreen: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(onboardingArchiveTypeOptions, id: \.onboardingType) { type in
                        Button(action: {
                            selectArchiveType(type)
                        }) {
                            HStack(alignment: .top, spacing: 16) {
                                type.onboardingDescriptionIcon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(8)
                                    .background(isArchiveTypeSelected(type) ? Color.white : Color.blue25)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(type.onboardingType)
                                        .font(.custom("Usual", size: 14))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue900)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text(type.onboardingDescription)
                                        .font(.custom("Usual", size: 12))
                                        .foregroundColor(.blue900)
                                        .lineSpacing(1.5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                archiveTypeSelectionIndicator(isSelected: isArchiveTypeSelected(type))
                                
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isArchiveTypeSelected(type) ? Color.blue25 : Color.clear)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        // .padding(.leading, 24)
                    }
                }
            }
            .background(Color.white)
        }
    }

    private func archiveTypeSelectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Image(.checkmarkGreen)
                    .frame(width: 16, height: 16)
            } else {
                Image(.accessRoleNotSelected)
                    .frame(width: 16, height: 16)
            }
        }
    }

    private var archiveTypeScreenTransition: AnyTransition {
        switch archiveTypeNavigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    private func isArchiveTypeSelected(_ type: ArchiveType) -> Bool {
        selectedArchiveType.tag == type.tag
    }

    private func openArchiveTypeSelection() {
        let showSelection = {
            archiveTypeNavigationDirection = .forward
            withAnimation(.easeInOut(duration: 0.28)) {
                showArchiveTypeSelection = true
            }
        }

        if isArchiveNameFieldFocused || isKeyboardVisible {
            dismissKeyboard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showSelection()
            }
            return
        }

        showSelection()
    }

    private func selectArchiveType(_ type: ArchiveType) {
        selectedArchiveType = type

        let closeSelection = {
            archiveTypeNavigationDirection = .backward
            withAnimation(.easeInOut(duration: 0.28)) {
                showArchiveTypeSelection = false
            }
        }

        if isArchiveNameFieldFocused || isKeyboardVisible {
            dismissKeyboard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                closeSelection()
            }
            return
        }

        closeSelection()
    }

    private func dismissKeyboard() {
        isArchiveNameFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func resetCreateArchiveForm() {
        newArchiveName = ""
        selectedArchiveType = .person
    }
    
    private var onboardingArchiveTypeOptions: [ArchiveType] {
        ArchiveType.allCases.filter { $0 != .nonProfit }
    }
    
    private func createArchiveAction() {
        let trimmedName = newArchiveName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            viewModel.errorMessage = "Archive name is required.".localized()
            return
        }
        
        viewModel.createArchive(name: trimmedName, type: selectedArchiveType) { success in
            if success {
                showCreateArchiveSheet = false
                resetCreateArchiveForm()
            }
        }
    }
}

private struct ArchiveTypeOpenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SharePreviewView(shareToken: "mock")
        }
    }
}
