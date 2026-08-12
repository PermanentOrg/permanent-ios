//
//  CustomToggleView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.11.2024.

import SwiftUI

/// A toggle scaled to an arbitrary width and height, wrapped in a button so the tap target stays
/// usable at small sizes.

struct CustomToggleView: View {
    @Binding var isOn: Bool
    var height: CGFloat = 20
    var width: CGFloat = 36
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .frame(width: width, height: height)
                .scaleEffect(min(height / 31, width / 51))
                .animation(.spring(), value: isOn)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: width + 20, height: height + 20, alignment: .top)
    }
}

struct CustomToggleView_Previews: PreviewProvider {
    static var previews: some View {
        CustomToggleView(isOn: .constant(true))
    }
} 
