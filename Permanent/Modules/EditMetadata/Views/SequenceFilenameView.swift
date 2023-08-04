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
            VStack(alignment: .leading) {
                Text("Base".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                TextField("Enter base text ", text: $viewModel.baseText)
                    .modifier(SmallXXRegularTextStyle())
                    .textFieldStyle(CustomTextFieldStyle())
                    .onChange(of: viewModel.baseText) { newValue in
                        print(newValue)
                    }
            }
            
            ZStack {
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Format".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                    PullDownButton(items: [
                        PullDownItem(id: 1, title: "Title & Date", onSelect: {}),
                        PullDownItem(id: 2, title: "Numbers", onSelect: {})
                    ])
                }
                .zIndex(10)
                    VStack(alignment: .leading) {
                        Text("Where".uppercased())
                            .textStyle(SmallXXXXXSemiBoldTextStyle())
                            .foregroundColor(Color.middleGray)
                        
                        PullDownButton(items: [
                            PullDownItem(id: 1, title: "After", onSelect: {}),
                            PullDownItem(id: 2, title: "Before", onSelect: {})
                        ])
                    }
                }
                .zIndex(10)
            }
            
            VStack(alignment: .leading) {
                Text("Date Value".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                ZStack {
                    PullDownButton(items: [
                        PullDownItem(id: 1, title: "Option 1", onSelect: {}),
                        PullDownItem(id: 2, title: "Option 2", onSelect: {})
                    ])
                    .zIndex(10)
                }
                
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
