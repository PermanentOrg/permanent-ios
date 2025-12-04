//
//  RenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.12.2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct RenameView: View {
    @StateObject private var viewModel: RenameViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var dismissOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isTextFieldFocused: Bool = false
    @State private var shakeTextField: Bool = false
    @State private var isRenaming: Bool = false
    @State private var showThumbnail: Bool = false
    
    // Height calculation: Header(64) + Separator(1) + Spacer(24) + TextField(48) + Spacer(24) + Button(56) + BottomPadding(32) = 249
    private let menuHeight: CGFloat = 249
    
    init(
        currentName: String,
        isFolder: Bool,
        thumbnailURL: String? = nil,
        onRename: @escaping (String) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: RenameViewModel(
            currentName: currentName,
            isFolder: isFolder,
            thumbnailURL: thumbnailURL,
            onRename: onRename,
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
                            Text(viewModel.title)
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
                    
                    // Item name input field
                    HStack(alignment: .center, spacing: 16) {
                        // Show folder icon for folders, thumbnail for files
                        if viewModel.isFolder {
                            Image(.folderIconFigma)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .fixedSize()
                        } else if let thumbnailURLString = viewModel.thumbnailURL,
                                  let url = URL(string: thumbnailURLString) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                                    .frame(width: 24, height: 24)
                                
                                ProgressView()
                                    .scaleEffect(0.5)
                                
                                WebImage(url: url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .opacity(showThumbnail ? 1 : 0)
                            }
                            .frame(width: 24, height: 24)
                            .fixedSize()
                        } else {
                            // Fallback file icon
                            Image(systemName: "doc.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.blue900)
                                .frame(width: 24, height: 24)
                                .fixedSize()
                        }
                        
                        RenameTextField(
                            text: $viewModel.itemName,
                            isFirstResponder: $isTextFieldFocused,
                            placeholder: viewModel.isFolder ? "Folder name" : "File name",
                            isReturnKeyEnabled: viewModel.isRenameButtonEnabled && !isRenaming,
                            onSubmit: {
                                renameItem()
                            },
                            onEmptySubmit: {
                                triggerShake()
                            }
                        )
                        .frame(maxWidth: .infinity)
                        
                        // Clear button
                        if !viewModel.itemName.isEmpty {
                            Button(action: {
                                viewModel.itemName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.blue900)
                                    .frame(width: 20, height: 20)
                            }
                            .fixedSize()
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.itemName.isEmpty)
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
                    
                    // Rename button
                    Button(action: {
                        if viewModel.isRenameButtonEnabled {
                            renameItem()
                        } else {
                            triggerShake()
                        }
                    }) {
                        Text("Rename")
                            .font(.custom("Usual-Regular", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((viewModel.isRenameButtonEnabled && !isRenaming) ? Color.blue900 : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!viewModel.isRenameButtonEnabled || isRenaming)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showThumbnail = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func dismissMenu() {
        isTextFieldFocused = false
        
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
    
    private func renameItem() {
        guard !isRenaming else { return }
        
        let newName = viewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            triggerShake()
            return
        }
        
        isRenaming = true
        isTextFieldFocused = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeIn(duration: 0.25)) {
                self.dismissOffset = self.menuHeight
                self.viewModel.isAnimating = false
                self.viewModel.backgroundOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                // Only call rename if name actually changed, otherwise just dismiss
                if self.viewModel.hasNameChanged {
                    self.viewModel.rename(newName: newName)
                } else {
                    self.viewModel.callOnDismiss()
                }
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

struct RenameView_Previews: PreviewProvider {
    static var previews: some View {
        RenameView(
            currentName: "My Folder",
            isFolder: true,
            thumbnailURL: nil,
            onRename: { _ in },
            onDismiss: {}
        )
    }
}
