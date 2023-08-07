//
//  SequenceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct SequenceFilenameView: View {
    @StateObject var viewModel: SequenceFilenameViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
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
            .zIndex(3)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Format".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                    
                    PullDownButton(selectedItem: $viewModel.selectedOption,
                                   items: [
                        PullDownItem(title: "Title & Date"),
                        PullDownItem(title: "Numbers")
                    ])
                    .padding(-5)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Where".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                    
                    PullDownButton(selectedItem: $viewModel.selectedOption,
                                   items: [
                        PullDownItem(title: "Before"),
                        PullDownItem(title: "After")
                    ])
                    .padding(-5)
                }
            }
            .offset(y: 90)
            .zIndex(2)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Date Value".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                
                PullDownButton(selectedItem: $viewModel.selectedOption,
                               items: [
                    PullDownItem(title: "Created"),
                    PullDownItem(title: "1")
                ])
                .padding(-5)
            }
            .offset(y: 180)
            .zIndex(1)
        }
        .padding(.top, 15)
    }
}
