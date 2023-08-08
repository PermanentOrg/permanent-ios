//
//  SequenceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct SequenceFilenameView: View {
    @StateObject var viewModel: SequenceFilenameViewModel
    @State var isSelectingFormat: Bool = false
    @State var isSelectingWhere: Bool = false
    @State var isSelectingDate: Bool = false
    
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
                                   ],
                                   isSelecting: $isSelectingFormat)
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
                                   ],
                                   isSelecting: $isSelectingWhere)
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
                               ],
                               isSelecting: $isSelectingDate)
                .padding(-5)
            }
            .offset(y: 180)
            .zIndex(1)
        }
        .padding(.top, 15)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    isSelectingFormat = false
                    isSelectingDate = false
                    isSelectingWhere = false
                    dismissKeyboard()
                }
        )
        .onDisappear {
            viewModel.fileNamePreview.wrappedValue = viewModel.selectedFiles.first?.name
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
