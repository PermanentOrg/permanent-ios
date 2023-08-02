//
//  SequenceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct SequenceFilenameView: View {
    @ObservedObject var viewModel: SequenceFilenameViewModel
    
    init(viewModel: SequenceFilenameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Base".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            TextField("Enter base text ", text: $viewModel.baseText)
                .modifier(SmallXXRegularTextStyle())
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: viewModel.baseText) { newValue in
                    print(newValue)
                }
            Spacer()
        }
        .padding(.top, 15)
    }
}

struct SequenceFilenameView_Previews: PreviewProvider {
    static var previews: some View {
        SequenceFilenameView(viewModel: SequenceFilenameViewModel())
    }
}
