//
//  AppendFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct AppendFilenameView: View {
    @ObservedObject var viewModel: AppendFilenameViewModel
    
    init(viewModel: AppendFilenameViewModel) {
        self.viewModel = viewModel
    }
    
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
                        print(newValue)
                    }
                
                Text("Where".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
            }
            
            VStack {
                PullDownButton(items: [
                    PullDownItem(title: "Before name"),
                    PullDownItem(title: "After Name")
                ])
                .padding(-5)
            }
            .offset(y: 120)
            
            Spacer()
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    
                }
        )
        .padding(.top, 15)
    }
}

struct AppendFilenameView_Previews: PreviewProvider {
    static var previews: some View {
        AppendFilenameView(viewModel: AppendFilenameViewModel())
    }
}
