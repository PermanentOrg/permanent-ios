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

    @State private var showArchivePicker = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                showArchivePicker = true
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
                            .frame(width: 48, height: 48)
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        if let archive = currentArchive {
                            Text("The \(archive.fullName ?? "Unknown") Archive")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        } else {
                            Text("Select an archive...")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if availableArchives.count > 1 {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if currentArchive != nil {
                Button(action: {
                    onViewInArchive()
                }) {
                    Text("Open")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.15, green: 0.18, blue: 0.35))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        .padding(.horizontal, 48)
        .padding(.bottom, 16)
        .sheet(isPresented: $showArchivePicker) {
            ArchivePickerView(archives: availableArchives, selectedArchive: currentArchive) { archive in
                onSelect(archive)
                showArchivePicker = false
            }
        }
    }
}

struct ArchivePickerView: View {
    let archives: [ArchiveVOData]
    let selectedArchive: ArchiveVOData?
    let onSelect: (ArchiveVOData) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select an archive...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            Divider()
            
            // Archive list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(archives, id: \.archiveID) { archive in
                        Button(action: {
                            onSelect(archive)
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
                                                .frame(width: 56, height: 56)
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
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("The \(archive.fullName ?? "Unknown") Archive")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    if archive.archiveID == AuthenticationManager.shared.session?.account.defaultArchiveID {
                                        Text("Default")
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if archive.archiveID == selectedArchive?.archiveID {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        
                        if archive.archiveID != archives.last?.archiveID {
                            Divider()
                                .padding(.leading, 96)
                        }
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 56, height: 56)
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
        SharePreviewArchiveSelectorView(currentArchive: ArchiveVOData.mock(), availableArchives: [ArchiveVOData.mock()], onSelect: { _ in }, onViewInArchive: { })
            .previewLayout(.sizeThatFits)
    }
}
