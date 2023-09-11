//
//  SequenceFilenameView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI
import Combine

struct SequenceFilenameView: View {
    @StateObject var viewModel: SequenceFilenameViewModel
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            VStack(alignment: .leading, spacing: 15) {
                Text("Base Title".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                TextField("Enter base text ", text: $viewModel.baseText)
                    .modifier(SmallXXRegularTextStyle())
                    .textFieldStyle(CustomTextFieldStyle())
                    .onChange(of: viewModel.baseText) { newValue in
                        viewModel.updatePreview()
                    }
                Spacer()
            }
            .zIndex(3)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Format".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                    
                    PullDownButton(selectedItem: $viewModel.selectedFormatOptions,
                                   items: viewModel.formatOptions,
                                   isSelecting: $viewModel.isSelectingFormat)
                    .padding(-5)
                    .onChange(of: viewModel.isSelectingFormat) { newValue in
                        if newValue {
                            viewModel.isSelectingWhere = false
                            viewModel.isSelectingAdditionalData = false
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Where".uppercased())
                        .textStyle(SmallXXXXXSemiBoldTextStyle())
                        .foregroundColor(Color.middleGray)
                    
                    PullDownButton(selectedItem: $viewModel.selectedWhereOptions,
                                   items: viewModel.whereOptions,
                                   isSelecting: $viewModel.isSelectingWhere)
                    .padding(-5)
                    .onChange(of: viewModel.isSelectingWhere) { newValue in
                        if newValue {
                            viewModel.isSelectingFormat = false
                            viewModel.isSelectingAdditionalData = false
                        }
                    }
                }
            }
            .offset(y: 90)
            .zIndex(2)
            
            let textTitle = viewModel.selectedFormatOptions?.title == "Count" ? "Start count at" : "Date Value"
            let textLimit = 3
            
            VStack(alignment: .leading, spacing: 15) {
                Text(textTitle.uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                
                if viewModel.selectedFormatOptions?.title == "Count" {
                    TextField("1", text: $viewModel.startNumberText)
                        .keyboardType(.numberPad)
                        .modifier(SmallXXRegularTextStyle())
                        .textFieldStyle(CustomTextFieldStyle())
                        .onReceive(Just(viewModel.startNumberText), perform: { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                self.viewModel.startNumberText = filtered
                            }
                            
                            if viewModel.startNumberText.count > textLimit {
                                viewModel.startNumberText = String(viewModel.startNumberText.prefix(textLimit))
                            }
                        })
                        .onChange(of: viewModel.baseText) { newValue in
                            viewModel.updatePreview()
                        }
                } else {
                    PullDownButton(selectedItem: $viewModel.selectedAdditionalOption,
                                   items: viewModel.additionalOptions,
                                   isSelecting: $viewModel.isSelectingAdditionalData)
                    .padding(-5)
                    .onChange(of: viewModel.isSelectingAdditionalData) { newValue in
                        if newValue {
                            viewModel.isSelectingWhere = false
                            viewModel.isSelectingFormat = false
                        }
                    }
                }
            }
            .offset(y: 180)
            .zIndex(1)
        }
        .padding(.top, 15)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    viewModel.updatePreview()
                    dismissKeyboard()
                }
        )
        .onDisappear {
            viewModel.baseText = ""
            viewModel.fileNamePreview.wrappedValue = viewModel.selectedFiles.first?.name
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
