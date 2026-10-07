//
//  FileActionConfirmationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import SwiftUI
import UIKit

/// The … sheet's delete and leave-share confirmation, for the long-press menu to present from UIKit.
/// It slides up from hidden, and dismisses before the action runs, so the host is gone before anything else presents.
struct FileActionConfirmationView: View {
    @State private var isPresented = false
    let file: FileModel
    let actionType: ConfirmationBottomAlertView.ActionType
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConfirmationBottomAlertView(
            isPresented: $isPresented,
            fileName: file.name,
            actionType: actionType,
            onConfirm: {
                onDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onConfirm()
                }
            },
            onCancel: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            },
            isFolder: file.type.isFolder
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = true
            }
        }
    }

    /// Present it with `animated: false`: SwiftUI owns the slide.
    static func host(for file: FileModel, _ actionType: ConfirmationBottomAlertView.ActionType, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) -> UIViewController {
        let confirmation = FileActionConfirmationView(file: file, actionType: actionType, onConfirm: onConfirm, onDismiss: onDismiss)
        let host = UIHostingController(rootView: confirmation)
        host.modalPresentationStyle = .overFullScreen
        host.view.backgroundColor = .clear
        return host
    }
}
