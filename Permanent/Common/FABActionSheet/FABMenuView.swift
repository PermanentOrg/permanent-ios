//
//  FABMenuView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.11.2025.
//

import SwiftUI

struct FABMenuView: View {
    @StateObject private var viewModel: FABMenuViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var dismissOffset: CGFloat = 0
    
    let onCreateFolder: () -> Void
    let onTakePhoto: () -> Void
    let onUploadPhotos: () -> Void
    let onBrowseFiles: () -> Void
    
    init(
        onCreateFolder: @escaping () -> Void,
        onTakePhoto: @escaping () -> Void,
        onUploadPhotos: @escaping () -> Void,
        onBrowseFiles: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.onCreateFolder = onCreateFolder
        self.onTakePhoto = onTakePhoto
        self.onUploadPhotos = onUploadPhotos
        self.onBrowseFiles = onBrowseFiles
        self._viewModel = StateObject(wrappedValue: FABMenuViewModel(onDismiss: {
            onDismiss?()
        }))
    }
    
    private let menuHeight: CGFloat = 370
    
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
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag indicator area at top
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 32)
                            .contentShape(Rectangle())
                        
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundColor(.clear)
                            .frame(width: 64, height: 4)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(4)
                            .padding(.bottom, 6)
                    }
                    
                    
                    // Menu content card
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundColor(.blue25)
                            .frame(height: 16)
                            .contentShape(Rectangle())
                        
                        // ScrollView for all menu items including Create New Folder
                        ScrollView {
                            VStack(spacing: 0) {
                                Button(action: {
                                    viewModel.dismissWithAnimation()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onCreateFolder()
                                    }
                                }) {
                                    HStack(alignment: .center, spacing: 16) {
                                        Image(.fabItemNewFolder)
                                            .font(.system(size: 20, weight: .regular))
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                                        
                                        Text("Create New Folder")
                                            .font(.custom("Usual-Regular", size: 14))
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue900)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .padding(.bottom, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue25)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Color.blue50)
                                
                                VStack(spacing: 32) {
                                    FABMenuItemView(
                                        assetImage: Image(.fabItemTakePhoto),
                                        title: "Take Photo or Video",
                                        action: {
                                            viewModel.dismissWithAnimation()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                onTakePhoto()
                                            }
                                        }
                                    )
                                    
                                    FABMenuItemView(
                                        assetImage: Image(.fabItemUploadPhotos),
                                        title: "Upload Photos from Library",
                                        action: {
                                            viewModel.dismissWithAnimation()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                onUploadPhotos()
                                            }
                                        }
                                    )
                                    
                                    FABMenuItemView(
                                        assetImage: Image(.fabItemBrowseFiles),
                                        title: "Browse Files...",
                                        isBold: true,
                                        action: {
                                            viewModel.dismissWithAnimation()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                onBrowseFiles()
                                            }
                                        }
                                    )
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 32)
                            }
                        }
                        .scrollDisabled(true)
                        .allowsHitTesting(!isDragging)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 290)
                    .background(Color.white)
                    .cornerRadius(24)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
                .frame(height: 370)
                .background(Color.clear)
                .contentShape(Rectangle())
                .offset(y: viewModel.isAnimating ? (dragOffset + dismissOffset) : 370)
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
                            let threshold: CGFloat = 120
                            
                            if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
                                // Set dismissOffset to current drag position before GestureState resets
                                dismissOffset = value.translation.height
                                dismissMenu()
                            }
                        }
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startPresentationAnimation()
        }
    }
    
    private func dismissMenu() {
        withAnimation(.easeIn(duration: 0.25)) {
            dismissOffset = menuHeight
            viewModel.isAnimating = false
            viewModel.backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewModel.callOnDismiss()
        }
    }
}



struct FABMenuView_Previews: PreviewProvider {
    static var previews: some View {
        FABMenuView(
            onCreateFolder: {},
            onTakePhoto: {},
            onUploadPhotos: {},
            onBrowseFiles: {}
        )
    }
}
