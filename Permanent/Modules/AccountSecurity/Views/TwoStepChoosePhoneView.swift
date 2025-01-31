//
//  TwoStepChoosePhoneView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.01.2025.

import SwiftUI

struct TwoStepChoosePhoneView: View {
    @StateObject var viewModel: TwoStepChoosePhoneViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Text("Choose Phone number")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}
