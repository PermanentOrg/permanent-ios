//
//  ConfirmationBottomAlertView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.11.2025.
//

import SwiftUI

struct ConfirmationBottomAlertView: View {
    @Binding var isPresented: Bool
    let fileName: String
    let actionType: ActionType
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    let isMultipleItems: Bool
    let isFolder: Bool
    
    enum ActionType {
        case delete
        case leaveShare
        case cancelUploads
        case uploadToPublicFolder

        func title(isFolder: Bool) -> String {
            switch self {
            case .delete:
                return "Are you sure you want to delete the selected \(isFolder ? "folder" : "file")"
            case .leaveShare:
                return "Are you sure you want to give up your access to the"
            case .cancelUploads:
                return "Are you sure you want to cancel all uploads?"
            case .uploadToPublicFolder:
                return "This is a public folder. Are you sure you want to upload here?"
            }
        }

        func multipleItemsTitle() -> Text {
            switch self {
            case .delete:
                return Text("Are you sure you want to delete the ")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
                + Text("selected items")
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.blue700)
                + Text("?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            case .leaveShare:
                return Text("Are you sure you want to give up your access to the ")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
                + Text("selected items")
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.blue700)
                + Text("?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            case .cancelUploads:
                return Text("Are you sure you want to cancel all uploads?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            case .uploadToPublicFolder:
                return Text("This is a public folder. Are you sure you want to upload here?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            }
        }

        var buttonText: String {
            switch self {
            case .delete:
                return "Delete"
            case .leaveShare:
                return "Leave share"
            case .cancelUploads:
                return "Cancel All"
            case .uploadToPublicFolder:
                return "Upload"
            }
        }

        /// True when the title is a complete standalone sentence — no filename is appended.
        var isStandaloneMessage: Bool {
            switch self {
            case .cancelUploads, .uploadToPublicFolder: return true
            default: return false
            }
        }

        /// Color of the confirm action button.
        var confirmButtonColor: Color {
            switch self {
            case .uploadToPublicFolder: return .blue900
            default: return .error500
            }
        }
    }
    
    init(
        isPresented: Binding<Bool>,
        fileName: String,
        actionType: ActionType,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil,
        isMultipleItems: Bool = false,
        isFolder: Bool = false
    ) {
        self._isPresented = isPresented
        self.fileName = fileName
        self.actionType = actionType
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.isMultipleItems = isMultipleItems
        self.isFolder = isFolder
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.blue700
                .opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.2), value: isPresented)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                    onCancel?()
                }
            
            if #available(iOS 26.0, *) {
                alertCard
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .offset(y: isPresented ? 0 : 400)
                    .animation(.easeOut(duration: 0.3), value: isPresented)
            } else {
                alertCard
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16,
                        style: .continuous
                    ))
                    .offset(y: isPresented ? 0 : 400)
                    .animation(.easeOut(duration: 0.3), value: isPresented)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
    
    private var alertCard: some View {
        VStack {
            titleView
                .padding(.top, 32)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 16) {
                Button(action: confirmAction) {
                    HStack {
                        Spacer()
                        Text(actionType.buttonText)
                            .fontWeight(.medium)
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(16)
                    .frame(height: 56)
                    .background(actionType.confirmButtonColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: cancelAction) {
                    HStack {
                        Spacer()
                        Text("Cancel")
                            .font(.custom("Usual-Regular", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.blue900)
                        Spacer()
                    }
                    .padding(16)
                    .frame(height: 56)
                    .background(Color.blue50)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.white))
        .padding(.horizontal, 0)
    }
    
    private var titleView: some View {
        Group {
            if actionType.isStandaloneMessage {
                Text(actionType.title(isFolder: false))
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            } else if isMultipleItems {
                actionType.multipleItemsTitle()
            } else {
                Text(actionType.title(isFolder: isFolder) + " ")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
                + Text(fileName)
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.blue700)
                + Text(actionType == .leaveShare ? " item?" : "?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
            }
        }
        .multilineTextAlignment(.center)
        .lineSpacing(6)
    }
    
    private func confirmAction() {
        if #available(iOS 17.0, *) {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = false
            } completion: {
                onConfirm()
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onConfirm()
            }
        }
    }
    
    private func cancelAction() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
        onCancel?()
    }
}

/// Wrapper used when presenting CancelUploads confirmation from UIKit via UIHostingController.
/// Starts hidden and animates in on appear so the sheet slides up (not fades in).
struct CancelUploadsConfirmationView: View {
    @State private var isPresented = false
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConfirmationBottomAlertView(
            isPresented: $isPresented,
            fileName: "",
            actionType: .cancelUploads,
            onConfirm: {
                onConfirm()
                onDismiss()
            },
            onCancel: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = true
            }
        }
    }
}

/// Wrapper used when presenting PublicFolderUpload confirmation from UIKit via UIHostingController.
/// Starts hidden and animates in on appear so the sheet slides up (not fades in).
/// onDismiss is called before the upload action so that the hosting controller is fully
/// removed before the action presents another view controller.
struct PublicFolderUploadConfirmationView: View {
    @State private var isPresented = false
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConfirmationBottomAlertView(
            isPresented: $isPresented,
            fileName: "",
            actionType: .uploadToPublicFolder,
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
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = true
            }
        }
    }
}

#Preview {
    VStack {
        ConfirmationBottomAlertView(
            isPresented: .constant(true),
            fileName: "Summer Holiday 2022",
            actionType: .leaveShare,
            onConfirm: {
                print("Confirmed")
            },
            onCancel: {
                print("Cancelled")
            },
            isMultipleItems: false
        )
    }
}
