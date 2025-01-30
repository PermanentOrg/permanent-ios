//
//  TopBannerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.01.2025.

import SwiftUI

struct TopBannerView: View {
    @Binding var isVisible: Bool
    @Binding var bannerDismissed: Bool
    
    var body: some View {
        VStack {
            if isVisible {
                VStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(.authTopBannerIcon)
                            .frame(width: 24, height: 24, alignment: .center)
                        HStack {
                            Text("The Permanent app may be briefly unavailable on")
                            + Text(" January 30th, 9:00 PM MST ")
                                .bold()
                            + Text("for routine maintenance. Thank you for your patience.")
                        }
                        .font(.custom("Usual-Regular", size: 14))
                        .lineSpacing(6)
                        .foregroundColor(.blue100)
                        
                        Button {
                            bannerDismissed = true
                            withAnimation {
                                isVisible = false
                            }
                        } label: {
                            Image(.authCloseIcon)
                                .frame(width: 24, height: 24, alignment: .center)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .background(Color(.blue900))
                .cornerRadius(12)
                //.transition(.move(edge: .top))
                .animation(.easeInOut, value: isVisible)
            }
            Spacer()
                .disabled(true)
        }
    }
}
