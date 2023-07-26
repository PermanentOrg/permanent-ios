//
//  BottomButtonsSectionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.07.2023.

import SwiftUI

struct BottomButtonsSectionView: View {
    @ObservedObject var viewModel: AddNewTagViewModel
    var showAddNewTag: Binding<Bool>?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 48)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                    Text("Cancel")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                        .frame(width: 118.11428, alignment: .top)
                }
            }
            Spacer(minLength: 15)
            Button {
                viewModel.addButtonPressed(completion: { status in
                    if status {
                        showAddNewTag?.wrappedValue = false
                        presentationMode.wrappedValue.dismiss()
                    }
                })
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 48)
                        .background(Color(red: 0.07, green: 0.11, blue: 0.29))
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 48)
                            .foregroundColor(.clear)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(addButtonText())
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(width: 146, alignment: .top)
                    }
                }
            }
        }
        .padding()
    }
    
    private func addButtonText() -> String {
        var addButtonText: String
        if viewModel.addedTags.count == .zero {
            addButtonText = "Add"
        } else if viewModel.addedTags.count == 1 {
            addButtonText = "Add 1 tag"
        } else {
            addButtonText = "Add \(viewModel.addedTags.count) tags"
        }
        return addButtonText
    }
}

struct BottomButtonsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        BottomButtonsSectionView(viewModel: AddNewTagViewModel(selectionTags: [], selectedFiles: []))
    }
}
