//
//  CustomStepperView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.11.2023.

import SwiftUI

struct CustomStepper : View {
    @Binding var value: Int
    var textColor: Color
    var step: Int = 1
    var textAfterValue: String = "GB / Recipient"
    @Binding var borderColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(borderColor, lineWidth: 1))
                .frame(height: 48)
            HStack {
                HStack(spacing: 16) {
                    Text("\(Int(value))").font(.system(.caption, design: .rounded))
                        .textStyle(SmallXRegularTextStyle())
                        .foregroundColor(.darkBlue)
                    Text("\(textAfterValue)".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(.darkBlue)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {
                        if self.value > 0 {
                            self.value -= self.step
                            self.feedback()
                        }
                    }, label: {
                        Image(.stepperMinus)
                            .renderingMode(.template)
                            .foregroundColor(Color.gray)
                    })
                    
                    Button(action: {
                        if self.value < 99 {
                            self.value += self.step
                            self.feedback()
                        }
                    }, label: {
                        Image(.stepperPlus)
                            .renderingMode(.template)
                            .foregroundColor(Color.gray)
                    })
                }
            }
            .cornerRadius(8)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }

    func feedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
