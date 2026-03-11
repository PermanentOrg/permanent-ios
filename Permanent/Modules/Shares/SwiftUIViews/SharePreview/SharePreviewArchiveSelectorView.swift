//
//  SharePreviewArchiveSelectorView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI

struct SharePreviewArchiveSelectorView: View {
    let currentArchive: ArchiveVOData?
    let availableArchives: [ArchiveVOData]
    let onSelect: (ArchiveVOData) -> Void
    let onViewInArchive: () -> Void
    let externalShowPicker: Binding<Bool>?
    let buttonTitle: String
    let isButtonDisabled: Bool
    let showButton: Bool
    let showOriginalArchiveBanner: Bool
    let accessRoleText: String?
    
    private var buttonBackgroundColor: Color {
        if buttonTitle == "Access Requested" {
            return Color.clear
        }
        return buttonTitle == "Request Access" ? Color.success500 : Color(red: 0.15, green: 0.18, blue: 0.35)
    }
    
    private var buttonTextColor: Color {
        if buttonTitle == "Access Requested" {
            return Color.success500
        }
        return Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                externalShowPicker?.wrappedValue = true
            }) {
                HStack(spacing: 12) {
                    if let archive = currentArchive {
                        if let thumbnailURL = archive.thumbURL200,
                           let url = URL(string: thumbnailURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        } else {
                            Image(systemName: "archivebox.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.purple)
                                .frame(width: 48, height: 48)
                        }
                    } else {
                        Image("SharePreviewArchiveNotselected")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VIEW SHARED ITEMS IN")
                            .lineLimit(1)
                            .font(.custom("Usual", size: 10))
                            .foregroundColor(.blue600)
                            .kerning(1.6)
                        
                        if let archive = currentArchive {
                            HStack {
                                Text("The ") +
                                Text("\(archive.fullName ?? "Unknown")").fontWeight(.semibold) +
                                Text(" Archive")
                            }
                                .font(.custom("Usual", size: 14))
                                .foregroundColor(.blue900)
                                .lineLimit(1)
                                .animation(nil, value: currentArchive?.archiveID)
                        } else {
                            Text("Select an archive...")
                                .font(.custom("Usual", size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue900)
                        }
                    }
                    
                    Spacer()
                    
                    if availableArchives.count > 1 {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.custom("Usual", size: 14))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Original archive banner with animated height
            if showOriginalArchiveBanner {
                Text("Shared from this archive.")
                    .font(.custom("Usual", size: 12))
                    .foregroundColor(.warning600)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.warning100)
                    .cornerRadius(7)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .opacity(showOriginalArchiveBanner ? 1.0 : 0.0)
                    .scaleEffect(showOriginalArchiveBanner ? 1.0 : 0.95, anchor: .top)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.95, anchor: .top).combined(with: .opacity)
                    ))
            }

            let showAccessRole = accessRoleText != nil
            if let accessRoleText = accessRoleText {
                HStack(spacing: 8) {
                    Text("Access role:")
                        .font(.custom("Usual", size: 12))
                        .foregroundColor(.blue600)
                        .padding(.leading, 4)

                    ZStack {
                        Text(accessRoleText)
                            .font(.custom("Usual", size: 10))
                            .kerning(1.6)
                            .foregroundColor(.blue600)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue25)
                            .cornerRadius(4)
                            .id(accessRoleText)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.2), value: accessRoleText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .opacity(showAccessRole ? 1.0 : 0.0)
                .scaleEffect(showAccessRole ? 1.0 : 0.95, anchor: .top)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.95, anchor: .top).combined(with: .opacity)
                ))
            }
            
            if currentArchive != nil && showButton {
                Button(action: {
                    if !isButtonDisabled {
                        onViewInArchive()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(buttonTitle)
                            .font(.custom("Usual", size: 14))
                            .fontWeight(.medium)
                        
                        if buttonTitle == "Access Requested" {
                            Image(systemName: "checkmark")
                                .font(.custom("Usual", size: 14))
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(buttonBackgroundColor)
                    .cornerRadius(12)
                }
                .buttonStyle(SharePreviewButtonStyle())
                .disabled(isButtonDisabled)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .id(buttonTitle)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        .animation(.easeInOut(duration: 0.3), value: showOriginalArchiveBanner)
        .animation(.easeInOut(duration: 0.3), value: accessRoleText != nil)
        .animation(.easeInOut(duration: 0.3), value: buttonTitle)
        .animation(.easeInOut(duration: 0.3), value: showButton)
        .padding(.horizontal, 48)
        .padding(.bottom, 16)
    }
}

struct ArchivePickerView: View {
    let archives: [ArchiveVOData]
    let selectedArchive: ArchiveVOData?
    let maxHeight: CGFloat
    let onSelect: (ArchiveVOData) -> Void
    let onCreateArchive: () -> Void
    var onClose: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    
    // Fixed header height
    private let headerHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 16) {
                Image(.sharePreviewArchive)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 8)
                
                Text("Select an archive...")
                    .font(.custom("Usual", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    if let onClose = onClose { onClose() } else { presentationMode.wrappedValue.dismiss() }
                }) {
                    Image(systemName: "xmark")
                        .font(.custom("Usual", size: 17))
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(height: headerHeight)
            
            Divider()
            
            // Archive list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        onCreateArchive()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "plus")
                                .font(.custom("Usual", size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.blue900)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text("Create a new Archive...")
                                .font(.custom("Usual", size: 14))
                                .foregroundColor(.blue900)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ForEach(archives, id: \.archiveID) { archive in
                        Button(action: {
                            onSelect(archive)
                            if let onClose = onClose { onClose() }
                        }) {
                            HStack(spacing: 16) {
                                // Archive thumbnail or gradient placeholder
                                if let thumbURL = archive.thumbURL200, let url = URL(string: thumbURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        case .failure(_), .empty:
                                            gradientPlaceholder(for: archive)
                                        @unknown default:
                                            gradientPlaceholder(for: archive)
                                        }
                                    }
                                } else {
                                    gradientPlaceholder(for: archive)
                                }
                                
                                HStack(alignment: .center) {
                                    Text("The ") +
                                    Text("\(archive.fullName ?? "Unknown")").fontWeight(.semibold) +
                                    Text(" Archive")
                                }
                                .font(.custom("Usual", size: 14))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(0.9)
                                .foregroundColor(.primary)
                                
                                Spacer()
                                
                            }

                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .background(archive.archiveID == selectedArchive?.archiveID ? .blue25 : Color.clear)
                    }
                }
            }
            .frame(height: maxHeight)
            .scrollDisabled(archives.count <= 5)
        }
        .background(Color(UIColor.systemBackground))
        .safeAreaInset(edge: .bottom) {
            Color(UIColor.systemBackground)
                .frame(height: 0)
        }
    }
    
    @ViewBuilder
    private func gradientPlaceholder(for archive: ArchiveVOData) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.6, blue: 0.9),
                    Color(red: 0.6, green: 0.4, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Text(extractInitials(from: archive.fullName ?? ""))
                .font(.custom("Usual", size: 20))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func extractInitials(from name: String) -> String {
        let words = name.split(separator: " ").map(String.init)
        if words.count >= 2 {
            let first = words.first?.prefix(1).uppercased() ?? ""
            let last = words.last?.prefix(1).uppercased() ?? ""
            return first + last
        } else if let first = words.first?.prefix(2).uppercased() {
            return String(first)
        }
        return ""
    }
}

// Custom button style to prevent white flash on press
struct SharePreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SharePreviewArchiveSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewArchiveSelectorView(
            currentArchive: ArchiveVOData.mock(),
            availableArchives: [ArchiveVOData.mock()],
            onSelect: { _ in },
            onViewInArchive: { },
            externalShowPicker: .constant(false),
            buttonTitle: "Open",
            isButtonDisabled: false,
            showButton: true,
            showOriginalArchiveBanner: true,
            accessRoleText: "VIEWER"
        )
            .previewLayout(.sizeThatFits)
    }
}
