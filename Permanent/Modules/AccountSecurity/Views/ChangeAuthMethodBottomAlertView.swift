//
//  DeleteBottomAlertView 2.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.02.2025.
import SwiftUI

struct ChangeAuthMethodBottomAlertView: View {
    @Binding var showErrorMessage: Bool
    @Binding var deleteMethodConfirmed: TwoFactorMethod?
    var twoFactorMethod: TwoFactorMethod?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if showErrorMessage {
                Color.blue700
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showErrorMessage = false
                        }
                        deleteMethodConfirmed = nil
                    }
                
                ZStack {
                    VStack(alignment: .center) {
                        HStack {
                            Text("To change the two-step verification method, you must first disable the currently enabled method.\nAre you sure you want to delete ") +
                            Text(String( "\(twoFactorMethod?.type.displayName ?? "") verification method?").lowercased()).bold()
                        }
                        .font(.custom("Usual-Regular", size: 14))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.blue700)
                        .padding(.top, 32)
                        .padding(.horizontal, 32)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                if #available(iOS 17.0, *) {
                                    withAnimation {
                                        showErrorMessage = false
                                    } completion: {
                                        deleteMethodConfirmed = twoFactorMethod
                                    }
                                } else {
                                    withAnimation {
                                        showErrorMessage = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        deleteMethodConfirmed = twoFactorMethod
                                    }
                                }
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Continue")
                                        .fontWeight(.medium)
                                        .font(.custom("Usual-Regular", size: 14))
                                        .foregroundColor(Color(.white))
                                    Spacer()
                                       
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(Color.error500)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                                .frame(maxWidth: .infinity)
                            })
                            Button(action: {
                                withAnimation {
                                    showErrorMessage = false
                                }
                                deleteMethodConfirmed = nil
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Cancel")
                                        .font(.custom("Usual-Regular", size: 14))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(.blue900))
                                    Spacer()
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(Color.blue50)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    deleteMethodConfirmed = nil
                                }
                            })
                        }
                        .padding(32)
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.white))
                .cornerRadius(12)
                .padding(.horizontal, 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
}
