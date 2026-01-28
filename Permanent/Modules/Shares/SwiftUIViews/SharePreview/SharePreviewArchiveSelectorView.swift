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
            
            if currentArchive != nil {
                Button(action: {
                    if !isButtonDisabled {
                        onViewInArchive()
                    }
                }) {
                    Text(buttonTitle)
                        .font(.custom("Usual", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isButtonDisabled ? Color.gray.opacity(0.5) : Color(red: 0.15, green: 0.18, blue: 0.35))
                        .cornerRadius(12)
                }
                .disabled(isButtonDisabled)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        .padding(.horizontal, 48)
        .padding(.bottom, 16)
    }
}

struct ArchivePickerView: View {
    let archives: [ArchiveVOData]
    let selectedArchive: ArchiveVOData?
    let maxHeight: CGFloat
    let onSelect: (ArchiveVOData) -> Void
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

struct SharePreviewArchiveSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        SharePreviewArchiveSelectorView(
            currentArchive: ArchiveVOData.mock(),
            availableArchives: [ArchiveVOData.mock()],
            onSelect: { _ in },
            onViewInArchive: { },
            externalShowPicker: .constant(false),
            buttonTitle: "Open",
            isButtonDisabled: false
        )
            .previewLayout(.sizeThatFits)
    }
}
