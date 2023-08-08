//
//  ReplaceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import SwiftUI

struct ReplaceFilenameView: View {
   @StateObject var viewModel: ReplaceFilenameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Find".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            TextField("Enter the text you want to find", text: $viewModel.findText)
                .modifier(SmallXXRegularTextStyle())
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: viewModel.findText) { newValue in
                }
            Text("Replace".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            TextField("Enter the replace text", text: $viewModel.replaceText)
                .modifier(SmallXXRegularTextStyle())
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: viewModel.replaceText) { newValue in
                   viewModel.updateReplacePreview()
                }
            Spacer()
        }
        .padding(.top, 15)
        .onTapGesture {
            dismissKeyboard()
        }.onDisappear {
            viewModel.findText = ""
            viewModel.replaceText = ""
            viewModel.fileNamePreview.wrappedValue = viewModel.selectedFiles.first?.name
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
