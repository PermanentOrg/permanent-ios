//
//  CreateNewFolderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.12.2025.
//

import SwiftUI

struct CreateNewFolderView: View {
    @StateObject private var viewModel: CreateNewFolderViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var dismissOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isTextFieldFocused: Bool = false
    @State private var shakeTextField: Bool = false
    @State private var isCreating: Bool = false
    
    // Height calculation: Header(64) + Separator(1) + Spacer(24) + TextField(48) + Spacer(24) + Button(56) + BottomPadding(32) = 249
    private let menuHeight: CGFloat = 249
    
    init(
        onCreateFolder: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: CreateNewFolderViewModel(
            onCreateFolder: onCreateFolder,
            onDismiss: {
                onDismiss?()
            }
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background overlay
            Color.black
                .opacity(viewModel.backgroundOpacity * 0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Header with centered title and close button
                    ZStack(alignment: .center) {
                            HStack(alignment: .center) {
                                Text("Create new folder")
                                    .font(.custom("Usual-Regular", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue900)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                
                                Spacer()
                                
                                Button(action: {
                                    dismissMenu()
                                }) {
                                    Image(.closeButtonV2)
                                        .frame(width: 24, height: 24)
                                }
                            }
                    }
                    .frame(height: 64)
                    .padding(.horizontal, 24)
                    
                    // Separator
                    Rectangle()
                        .fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                        .frame(height: 1)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Folder name input field
                    HStack(alignment: .center, spacing: 16) {
                        Image(.folderIconFigma)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .fixedSize()
                        
                        FolderNameTextField(
                            text: $viewModel.folderName,
                            isFirstResponder: $isTextFieldFocused,
                            isReturnKeyEnabled: viewModel.isCreateButtonEnabled && !isCreating,
                            onSubmit: {
                                createFolder()
                            },
                            onEmptySubmit: {
                                triggerShake()
                            }
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Clear button
                        if !viewModel.folderName.isEmpty {
                            Button(action: {
                                viewModel.folderName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.blue900)
                                    .frame(width: 20, height: 20)
                            }
                            .fixedSize()
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.folderName.isEmpty)
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .padding(.vertical, 0)
                    .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .leading)
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.2), radius: 24, x: 0, y: 0)
                    .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.04), radius: 0, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(shakeTextField ? Color.error500 : Color(red: 0.91, green: 0.91, blue: 0.93), lineWidth: shakeTextField ? 2 : 1)
                    )
                    .offset(x: shakeTextField ? -5 : 0)
                    .animation(.easeInOut(duration: 0.06).repeatCount(3, autoreverses: true), value: shakeTextField)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Create button
                    Button(action: {
                        if viewModel.isCreateButtonEnabled {
                            createFolder()
                        } else {
                            triggerShake()
                        }
                    }) {
                        Text("Create")
                            .font(.custom("Usual-Regular", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((viewModel.isCreateButtonEnabled && !isCreating) ? Color.blue900 : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!viewModel.isCreateButtonEnabled || isCreating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .frame(height: menuHeight)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipped()
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .offset(y: viewModel.isAnimating ? (dragOffset + dismissOffset) : menuHeight)
                .highPriorityGesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if value.translation.height > 0 {
                                state = value.translation.height
                            }
                        }
                        .onChanged { value in
                            if value.translation.height > 0 {
                                isDragging = true
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold: CGFloat = 100
                            
                            if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
                                dismissOffset = value.translation.height
                                dismissMenu()
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(.container)
        .onAppear {
            viewModel.startPresentationAnimation()
            // Auto-focus the text field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func dismissMenu() {
        // Dismiss keyboard first
        isTextFieldFocused = false
        
        // Wait for keyboard to dismiss, then animate view dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeIn(duration: 0.25)) {
                self.dismissOffset = self.menuHeight
                self.viewModel.isAnimating = false
                self.viewModel.backgroundOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.viewModel.callOnDismiss()
            }
        }
    }
    
    private func createFolder() {
        guard !isCreating else { return }
        
        let folderName = viewModel.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folderName.isEmpty else {
            triggerShake()
            return
        }
        
        // Prevent double submission
        isCreating = true
        
        // Dismiss keyboard first
        isTextFieldFocused = false
        
        // Wait for keyboard to dismiss, then animate view dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeIn(duration: 0.25)) {
                self.dismissOffset = self.menuHeight
                self.viewModel.isAnimating = false
                self.viewModel.backgroundOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.viewModel.createFolder(name: folderName)
            }
        }
    }
    
    private func triggerShake() {
        shakeTextField = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeTextField = false
        }
    }
}

struct CreateNewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewFolderView(
            onCreateFolder: { _ in },
            onDismiss: {}
        )
    }
}
