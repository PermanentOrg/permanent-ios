//
//  DividentProgressBar.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct DividerSmallBarView: View {
    enum DividerType {
        case gradient, empty
    }
    
    @State var type: DividerType = .empty
    var color: Color = .white
    var gradient: LinearGradient = Gradient.purpleYellowGradient
    var height: CGFloat = Constants.Design.isPhone ? 2 : 4
    
    var body: some View {
        if type == .gradient {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .background(Gradient.purpleYellowGradient)
                .cornerRadius(30)
        } else {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .background(color)
                .cornerRadius(30)
                .opacity(0.1)
        }
    }
}
