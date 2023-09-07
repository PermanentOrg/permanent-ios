//
//  CustomDialogView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.09.2023.

import SwiftUI

struct CustomDialogView: View {
    @Binding var isActive: Bool
    let title: String
    let message: String
    let buttonTitle: String
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
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text(title)
                            .textStyle(RegularBoldTextStyle())
                            .multilineTextAlignment(.center)
                            .foregroundColor(.darkBlue)
                            .padding()
                        Text(message)
                            .textStyle(SmallXRegularTextStyle())
                            .multilineTextAlignment(.center)
                            .foregroundColor(.darkBlue)
                            .frame(width: 216)
                            .padding(.horizontal)
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
                        Button {
                            close()
                        } label: {
                            Text("Cancel")
                                .multilineTextAlignment(.center)
                        }
                        .buttonStyle(CustomButtonStyle(backgroundColor: .galleryGray, foregroundColor: .darkBlue))
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
            . ignoresSafeArea()
        } else {
            VStack {
                Text(title)
                    .font(.title2)
                    .bold()
                    .padding()
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
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
