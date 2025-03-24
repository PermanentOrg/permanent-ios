//
//  DeleteModalAlertView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.03.2025.
import SwiftUI

struct TwoStepTabletModalAlertView: View {
    @Binding var showErrorMessage: Bool
    @Binding var deleteMethodConfirmed: TwoFactorMethod?
    var twoFactorMethod: TwoFactorMethod?
    var deleteMessage: Bool = false
    
    var body: some View {
                ZStack {
                    VStack(spacing: deleteMessage ? 48 : 64) {
                        if deleteMessage {
                            HStack {
                                Text("Are you sure you want to delete your ") +
                                Text("\(twoFactorMethod?.type.displayName ?? "")").bold() +
                                Text(" two-step verification method?")
                            }
                            .font(.custom("Usual-Regular", size: 14))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .foregroundColor(.blue700)
                        } else {
                            HStack {
                                Text("To change the two-step verification method, you must first disable the currently enabled method.\nAre you sure you want to delete ") +
                                Text(String( "\(twoFactorMethod?.type.displayName ?? "") verification method?").lowercased()).bold()
                            }
                            .font(.custom("Usual-Regular", size: 14))
                            .lineSpacing(6)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.blue700)
                        }
                        
                        HStack(spacing: 16) {
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
                        }
                    }
                    .padding(.horizontal, 64)
                }
                .background(Color(.white))
                .cornerRadius(12)
    }
}
