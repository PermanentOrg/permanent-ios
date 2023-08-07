//
//  AppendFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct AppendFilenameView: View {
    @StateObject var viewModel: AppendFilenameViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            VStack(alignment: .leading, spacing: 15) {
                Text("Text".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                TextField("Enter the text you want to find", text: $viewModel.textToAppend)
                    .modifier(SmallXXRegularTextStyle())
                    .textFieldStyle(CustomTextFieldStyle())
                    .onChange(of: viewModel.textToAppend) { newValue in
                        viewModel.updateAppendPreview()
                    }
                Text("Where".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                Spacer()
            }
            
            VStack {
                PullDownButton(
                    selectedItem: $viewModel.selectedOption,
                    items: [
                        PullDownItem(title: "Before name"),
                        PullDownItem(title: "After Name")
                ])
                .padding(-5)
            }
            .offset(y: 120)
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    
                }
        )
        .padding(.top, 15)
        .onDisappear {
            viewModel.fileNamePreview.wrappedValue = viewModel.selectedFiles.first?.name
        }
    }
}
