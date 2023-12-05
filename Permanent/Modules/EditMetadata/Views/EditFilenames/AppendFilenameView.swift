//
//  AppendFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct AppendFilenameView: View {
    @StateObject var viewModel: AppendFilenameViewModel
    @State var isSelectingOption: Bool = false
    
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
                    ],
                    isSelecting: $isSelectingOption)
                .padding(-5)
            }
            .offset(y: 120)
        }
        .padding(.top, 15)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    dismissKeyboard()
                }
        )
        .onDisappear {
            viewModel.textToAppend = ""
            viewModel.fileNamePreview.wrappedValue = viewModel.selectedFiles.first?.name
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
