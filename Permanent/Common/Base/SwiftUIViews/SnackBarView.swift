//
//  SnackBarView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 15.04.2024.

import SwiftUI

struct SnackBarView: View {
    @Binding var show: Bool
    private var messsage: String
    
    init(message: String, show: Binding<Bool>) {
        self.messsage = message
        _show = show
    }

    var body: some View {
        VStack {
            Spacer()
            if  show {
                Text(messsage)
                    .textStyle(SmallRegularTextStyle())
                    .foregroundColor(Color.middleGray)
                    .frame(minWidth: 240, minHeight: 64)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(32)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 16)
                    .padding(.bottom, 32)
                
                // Optionally add a button to dismiss
            }
        }
        .animation(.spring(), value: show) // Animation for showing/hiding
        .edgesIgnoringSafeArea(.bottom) // Overlay the whole window
    }
}

#Preview {
    SnackBarView(message: "Hello", show: .constant(true))
}
