//
//  CustomDialogView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.09.2023.

import SwiftUI

/// Displays a simple two options alert with title and context
///  - Parameters:
///     - title: This is the tile of the alert
///     - message: The body of the alert
///     - buttonTitle: The text of the confirm button
///     - action: a closure to run when is confirmed.
///  - Returns: Returns a view of a simple alert with two options as a View
struct CustomDialogView: View {
    @Binding var isActive: Bool
    let title: String
    let message: String?
    let buttonTitle: String
    var addCornerRadius: Bool = false
    let action: () -> ()
    @State private var offset: CGFloat = 1000
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ZStack {
                Color(.black)
                    .opacity(0.2)
                    .onTapGesture {
                        close()
                    }
                ZStack {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Text(title)
                                .textStyle(RegularBoldTextStyle())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.darkBlue)
                                .frame(width: 216)
                                .padding()
                            if let message = message {
                                Text(message)
                                    .textStyle(SmallXRegularTextStyle())
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.darkBlue)
                                    .frame(width: 216)
                                    .padding(.horizontal)
                            }
                        }
                        VStack(spacing: 8) {
                            Button {
                                action()
                                close()
                            } label: {
                                Text(buttonTitle)
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(CustomButtonStyle(backgroundColor: .darkBlue, foregroundColor: .white))
                            .cornerRadius(addCornerRadius ? 8 : 0)
                            Button {
                                close()
                            } label: {
                                Text("Cancel")
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(CustomButtonStyle(backgroundColor: .galleryGray, foregroundColor: .darkBlue))
                            .cornerRadius(addCornerRadius ? 8 : 0)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 20)
                    .padding(30)
                    .offset(x: 0, y: offset)
                    .onAppear {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
                .padding(.horizontal, 48)
            }
            .ignoresSafeArea()
        } else {
            VStack {
                Text(title)
                    .font(.title2)
                    .bold()
                    .padding()
                if let message = message {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Button {
                    action ()
                } label: {
                    ZStack {
                        RoundedRectangle (cornerRadius: 20)
                            .foregroundColor(.red)
                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(30)
        }
    }
    
    func close() {
        withAnimation(.spring()) {
            offset = 1000
        }
        isActive = false
    }
}

struct CustomDialogView_Previews: PreviewProvider {
    static var previews: some View {
        CustomDialogView(isActive: .constant(true), title: "Need Access", message: "Are you sure you want to give access to photo library?", buttonTitle: "Give access", action: {
        })
    }
}
