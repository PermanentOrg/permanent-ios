//
//  RevokeBottomAlertView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.09.2025.
//

import SwiftUI

struct RevokeBottomAlertView: View {
    @Binding var isPresented: Bool
    let onRevoke: () -> Void
    let onCancel: (() -> Void)?
    
    init(
        isPresented: Binding<Bool>,
        onRevoke: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.onRevoke = onRevoke
        self.onCancel = onCancel
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
            
            alertCard
                .offset(y: isPresented ? 0 : 400)
                .opacity(isPresented ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: isPresented)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
    
    private var alertCard: some View {
        VStack {
            HStack {
                Spacer()
                Text("Are you sure you want to ")
                + Text("revoke this share link?")
                    .bold()
                Spacer()
            }
                .font(.custom("Usual-Regular", size: 14))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundColor(.blue700)
                .padding(.top, 32)
                .padding(.horizontal, 32)
            
            VStack(spacing: 16) {
                Button(action: revokeAction) {
                    HStack {
                        Spacer()
                        Text("Revoke link")
                            .fontWeight(.medium)
                            .font(.custom("Usual-Regular", size: 14))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(16)
                    .frame(height: 56)
                    .background(Color.error500)
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
        .cornerRadius(12)
        .padding(.horizontal, 0)
    }
    
    private func revokeAction() {
        if #available(iOS 17.0, *) {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = false
            } completion: {
                onRevoke()
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onRevoke()
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

#Preview {
    RevokeBottomAlertView(
        isPresented: .constant(true),
        onRevoke: {
            print("Revoke tapped")
        },
        onCancel: {
            print("Cancel tapped")
        }
    )
}


