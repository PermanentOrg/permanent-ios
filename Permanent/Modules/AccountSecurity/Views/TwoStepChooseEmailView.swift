//
//  TwoStepChooseEmailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.01.2025.

import SwiftUI

struct TwoStepChooseEmailView: View {
    @StateObject var viewModel: TwoStepChooseEmailViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Text("Choose Email")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}
