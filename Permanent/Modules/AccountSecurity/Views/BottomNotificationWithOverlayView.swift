//
//  TwoStepBottomNotificationView 2.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2025.
import SwiftUI

struct BottomNotificationWithOverlayView: View {
    let message: BannerBottomMessage
    var showRightButton: Bool = true
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
                .disabled(true)
            if isVisible {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        HStack(alignment: .top) {
                            Group {
                                if message.isError {
                                    Image(.explanationMarkRed)
                                } else {
                                    Image(.checkmarkGreen)
                                }
                                Text("\(message.text)")
                                    .font(.custom("Usual-Regular", size: 14))
                                    .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .lineSpacing(1.5)
                                    .frame(minHeight: 24)
                            }
                        }
                        Spacer()
                        if message.isError && showRightButton {
                            Button(action: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                withAnimation {
                                    isVisible = false
                                }
                            }, label: {
                                Image(.authCloseBannerSuccess)
                                    .renderingMode(.template)
                                    .foregroundColor(.error500)
                            })
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    //.frame(height: 64)
                    .background(message.isError ? Color(red: 1, green: 0.89, blue: 0.89) : Color(red: 0.92, green: 0.99, blue: 0.95))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke( message.isError ? Color.error200 : Color.success200, lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.12), radius: 16, x: 0, y: 24)
                    Color.clear
                        .frame(height: 32)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: isVisible)
            }
        }
    }
}

#Preview {
    BottomNotificationWithOverlayView(
        message: .emptyPinCode,
        isVisible: .constant(true)
    )
}
