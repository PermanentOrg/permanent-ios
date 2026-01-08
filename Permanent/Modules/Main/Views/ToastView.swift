//
//  ToastView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Extracted from SwiftUIFolderNavigationView for reusability
//

import SwiftUI

// MARK: - Toast View
// Note: ToastType is defined in MainViewState.swift

@available(iOS 17, *)
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17, *)
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastView(message: "Success message", type: .success, onDismiss: {})
            ToastView(message: "Error message", type: .error, onDismiss: {})
            ToastView(message: "Info message", type: .info, onDismiss: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
