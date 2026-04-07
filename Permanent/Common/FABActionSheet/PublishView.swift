//
//  PublishView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.12.2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct PublishView: View {
    @StateObject private var viewModel: PublishViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var dismissOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isPublishing: Bool = false
    @State private var showThumbnail: Bool = false
    
    private var menuHeight: CGFloat {
        UIScreen.main.bounds.height * 0.75
    }
    
    private var thumbnailSize: CGFloat {
        UIScreen.main.bounds.width - 48
    }
    
    init(
        fileName: String,
        isFolder: Bool,
        thumbnailURL: String? = nil,
        thumbnailURL2000: String? = nil,
        onPublish: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: PublishViewModel(
            fileName: fileName,
            isFolder: isFolder,
            thumbnailURL: thumbnailURL,
            thumbnailURL2000: thumbnailURL2000,
            onPublish: onPublish,
            onDismiss: {
                onDismiss?()
            }
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(viewModel.backgroundOpacity * 0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }
            
            VStack(spacing: 0) {
                Group {
                    if #available(iOS 26.0, *) {
                        VStack(spacing: 0) { panelBody }
                            .frame(height: menuHeight)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(32)
                    } else {
                        VStack(spacing: 0) { panelBody }
                            .frame(height: menuHeight)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(16, corners: [.topLeft, .topRight])
                    }
                }
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
                withAnimation(.easeIn(duration: 0.2)) {
                    showThumbnail = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var panelBody: some View {
        // Top padding for iOS 26 (glass button breathing room)
        if #available(iOS 26.0, *) {
            Spacer().frame(height: 8)
        }
        
        // Header with centered title and close button
        ZStack(alignment: .center) {
            Text(viewModel.title)
                .font(.custom("Usual-Regular", size: 16))
                .fontWeight(.medium)
                .foregroundColor(.blue900)
                .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                if #available(iOS 26.0, *) {
                    Button(action: {
                        dismissMenu()
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
                        dismissMenu()
                    }) {
                        Image(.closeButtonV2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .frame(height: 64)
        .padding(.horizontal, 24)
        
        // Separator (hidden on iOS 26+)
        if #unavailable(iOS 26.0) {
            Rectangle()
                .fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                .frame(height: 1)
        }
        
        Spacer()
        
        thumbnailView
        
        Spacer()
        
        VStack(spacing: 24) {
            HStack {
                Text("Are you sure you want to create a publicly viewable copy of ") +
                Text(viewModel.fileName).bold() +
                Text(" in your Public Workspace?")
            }
            .font(.custom("Usual-Regular", size: 14))
            .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 12)
            
            Button(action: {
                publishItem()
            }) {
                Text("Publish")
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPublishing ? Color.gray.opacity(0.3) : Color.blue900)
                    )
            }
            .disabled(isPublishing)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if viewModel.isFolder {
            Image(.folderIconBig)
                .frame(width: thumbnailSize, height: thumbnailSize)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                    .frame(width: thumbnailSize, height: thumbnailSize)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue900))
                
                if let lowResURLString = viewModel.thumbnailURL,
                   let lowResURL = URL(string: lowResURLString) {
                    WebImage(url: lowResURL)
                        .resizable()
                        .scaledToFill()
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(showThumbnail && !viewModel.isHighResThumbnailLoaded ? 1 : 0)
                }
                
                if let highResURLString = viewModel.thumbnailURL2000,
                   let highResURL = URL(string: highResURLString) {
                    WebImage(url: highResURL)
                        .onSuccess { _, _, _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.isHighResThumbnailLoaded = true
                            }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(showThumbnail && viewModel.isHighResThumbnailLoaded ? 1 : 0)
                }
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
        }
    }
    
    private func dismissMenu() {
        withAnimation(.easeIn(duration: 0.25)) {
            self.dismissOffset = self.menuHeight
            self.viewModel.isAnimating = false
            self.viewModel.backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.viewModel.callOnDismiss()
        }
    }
    
    private func publishItem() {
        guard !isPublishing else { return }
        
        isPublishing = true
        
        withAnimation(.easeIn(duration: 0.25)) {
            self.dismissOffset = self.menuHeight
            self.viewModel.isAnimating = false
            self.viewModel.backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.viewModel.publish()
        }
    }
}

extension View {
    func scaleTransform(_ scale: CGFloat) -> some View {
        self.scaleEffect(scale)
    }
}

struct PublishView_Previews: PreviewProvider {
    static var previews: some View {
        PublishView(
            fileName: "August_Hike_005",
            isFolder: false,
            thumbnailURL: nil,
            thumbnailURL2000: nil,
            onPublish: {},
            onDismiss: {}
        )
    }
}
