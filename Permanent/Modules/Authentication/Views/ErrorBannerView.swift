//
//  ErrorBannerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.09.2024.

import SwiftUI

enum ErrorBannerMessage {
    case invalidData
    case invalidCredentials
    case error
    case none
    
    var text: String {
        switch self {
        case .invalidData:
            return "The entered data is invalid"
        case .invalidCredentials:
            return "Incorrect email or password."
        case .error:
            return .errorMessage
        case .none:
            return ""
        }
    }
}

struct ErrorBannerView: View {
    let message: ErrorBannerMessage
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
                .disabled(true)
            
            if isVisible {
                HStack(spacing: 0) {
                    HStack {
                        Group {
                            Image(.authNotificationError)
                            // Body/Regular
                            Text("\(message.text)")
                                
                                .font(.custom("Usual-Regular", size: 14))
                                .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.22))
                        }
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                        isVisible = false
                    }
                    }, label: {
                        Text("OK")
                            .font(.custom("Usual-Regular", size: 14)
                                .weight(.medium)
                            )
                            .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                    })
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color(red: 1, green: 0.89, blue: 0.89))
                .cornerRadius(12)
                .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.12), radius: 16, x: 0, y: 24)
                .transition(.move(edge: .bottom)) // Slide in from the bottom
                .animation(.easeInOut(duration: 0.3), value: isVisible) // Smooth animation

                
            }
        }
        // .padding(.bottom, 50) // Adjust this padding as needed for the notification's position
    }
}
