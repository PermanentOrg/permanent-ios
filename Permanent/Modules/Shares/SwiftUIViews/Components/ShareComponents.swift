//
//  ShareComponents.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2025.
//

import SwiftUI

// MARK: - Share Card Component
struct ShareCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            action()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .opacity(isLoading ? 0.6 : 1.0)
        .disabled(isLoading)
    }
}

// MARK: - File Info Component
struct FileInfoView: View {
    let fileName: String
    let fileSize: String
    let fileDate: String
    let thumbnailURL: String?
    let isFolder: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // File Thumbnail
            AsyncImage(url: URL(string: thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: isFolder ? "folder.fill" : "doc.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // File Details
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    if !fileSize.isEmpty {
                        Text(fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(fileDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Search Field Component
struct SearchFieldView: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Section Header Component
struct ShareSectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Spacer()
        }
    }
}

// MARK: - Action Button Component
struct ActionButtonView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct LinkCopyNotificationView: View {
    @State private var isVisible = false
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .medium))
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
            
            Text("Link copied to clipboard")
                .foregroundColor(.white)
                .font(.custom("Usual-Regular", size: 14))
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isVisible)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        )
        .onAppear {
            withAnimation {
                isVisible = true
                checkmarkScale = 1.0
            }
        }
    }
}

struct ArchiveAccessNotificationView: View {
    let message: String
    @State private var isVisible = false
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .medium))
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
            
            Text(message)
                .foregroundColor(.white)
                .font(.custom("Usual-Regular", size: 14))
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isVisible)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        )
        .onAppear {
            withAnimation {
                isVisible = true
                checkmarkScale = 1.0
            }
        }
    }
}

struct LinkSettingsNotificationView: View {
    @State private var isVisible = false
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .medium))
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
            
            Text("Link settings have been updated.")
                .foregroundColor(.white)
                .font(.custom("Usual-Regular", size: 14))
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isVisible)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        )
        .onAppear {
            withAnimation {
                isVisible = true
                checkmarkScale = 1.0
            }
        }
    }
}

struct RevokeLinkNotificationView: View {
    @State private var isVisible = false
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .medium))
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
            
            Text("Link has been revoked.")
                .foregroundColor(.white)
                .font(.custom("Usual-Regular", size: 14))
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isVisible)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        )
        .onAppear {
            withAnimation {
                isVisible = true
                checkmarkScale = 1.0
            }
        }
    }
}
struct AnimatedTextWithDotsView: View {
    @State private var dotCount = 0
    
    var body: some View {
        Text("Creating link" + String(repeating: ".", count: dotCount))
            .font(.custom("Usual-Regular", size: 14))
            .foregroundStyle(Gradient.purpleYellowGradientForText)
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

struct ExpirationOptionView: View {
    let icon: Image
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                icon
                    .foregroundColor(Color.blue900)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.custom(isSelected ? "Usual-Medium" : "Usual-Regular", size: 14))
                    .foregroundColor(Color.blue900)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Group {
                    if isSelected {
                        Color.blue25
                    } else {
                        Color.white
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .cornerRadius(12)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.purple, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .opacity(isSelected ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.3), value: isSelected)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue100, lineWidth: 1)
                            .opacity(isSelected ? 0.0 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isSelected)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
