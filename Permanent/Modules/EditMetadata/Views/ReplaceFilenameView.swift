//
//  ReplaceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import SwiftUI

struct ReplaceFilenameView: View {
    @ObservedObject var viewModel: ReplaceFilenameViewModel
    
    init(viewModel: ReplaceFilenameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Find".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            TextField("Enter the text you want to find", text: $viewModel.findText)
                .modifier(SmallXXRegularTextStyle())
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: viewModel.findText) { newValue in
                    print(newValue)
                }
            Text("Replace".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            TextField("Enter the replace text", text: $viewModel.replaceText)
                .modifier(SmallXXRegularTextStyle())
                .textFieldStyle(CustomTextFieldStyle())
                .onChange(of: viewModel.replaceText) { newValue in
                    print(newValue)
                }
            Spacer()
        }
        .padding(.top, 15)
    }
}

struct ReplaceFilenameView_Previews: PreviewProvider {
    static var previews: some View {
        @State var newTag: String = ""
        
        ReplaceFilenameView(viewModel: ReplaceFilenameViewModel())
    }
}
