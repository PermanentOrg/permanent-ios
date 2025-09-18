//
//  SelectableOptionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2025.
import SwiftUI

struct SelectableOptionView<T: SelectableOption>: View {
    let option: T
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                option.icon
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundColor(option.iconColor)
                    .padding(10)
                    .background(isSelected ? Color.white : Color.success50)
                    .cornerRadius(4)
                    .padding(.top, -10)
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(option.title)
                        .font(.custom("Usual-Medium", size: 14))
                        .foregroundColor(Color.blue900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(option.description)
                        .font(.custom("Usual-Regular", size: 12))
                        .foregroundColor(Color.blue900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        //.lineLimit(0)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .frame(width: 24, height: 24, alignment: .center)
                        .foregroundStyle(.white)

                    if isSelected {
                        Image(.checkmarkGreen)
                            .renderingMode(.template)
                            .foregroundColor(Color.success500)
                            .frame(width: 16, height: 16, alignment: .center)
                    } else {
                        Circle()
                            .stroke(Color.blue100, lineWidth: 2)
                            .frame(width: 16, height: 16, alignment: .center)
                    }
                }
            }
            .padding(24)
            .padding(.top, 10)
            .background(isSelected ? Color.blue25 : Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
