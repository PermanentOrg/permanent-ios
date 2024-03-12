//
//  DividentProgressBar.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct DividerSmallBar: View {
    enum DividerType {
        case gradient, empty
    }
    
    @State var type: DividerType = .empty
    var color: Color = .white
    var gradient: LinearGradient = Gradient.purpleYellowGradient
    
    var body: some View {
        if type == .gradient {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2)
                .background(Gradient.purpleYellowGradient)
                .cornerRadius(30)
        } else {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2)
                .background(color)
                .cornerRadius(30)
                .opacity(0.1)
        }
    }
}
