//
//  AddNewTagView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.07.2023.

import SwiftUI

struct AddNewTagView: View {
    @ObservedObject var viewModel: AddNewTagViewModel
    @State private var dismissView: Bool = false
    @State private var newTag = ""
    var showAddNewTag: Binding<Bool>?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(viewModel: AddNewTagViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack {
                        createNewTag
                        Spacer(minLength: 22)
                        recentTags
                        Spacer(minLength: 13)
                        AddTagsView(allTags: $viewModel.filteredUncommonTags, addedTags: $viewModel.addedTags)
                    }
                    .padding()
                    .navigationBarTitle("New Tag", displayMode: .inline)
                    .navigationBarItems(leading: Image("metadataTags")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24))
                }
            }
            .padding(.bottom, 85)
            VStack {
                Spacer()
                BottomButtonsSectionView(viewModel: viewModel, showAddNewTag: showAddNewTag)
                    .padding()
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .onAppear {
            viewModel.refreshTags()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                viewModel.showAlert = false
            })
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var createNewTag: some View {
        VStack {
            HStack {
                Text("Create New Tag".uppercased())
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .foregroundColor(Color.middleGray)
                Spacer()
            }
            Spacer(minLength: 9)
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 48)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.99).opacity(0.5))
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .inset(by: 0.5)
                            .stroke(Color(red: 0.96, green: 0.96, blue: 0.99), lineWidth: 1)
                    )
                HStack {
                    TextField("Enter new tag", text: $newTag)
                        .modifier(SmallXXRegularTextStyle())
                        .padding(.leading, 16)
                        .foregroundColor(Color.darkBlue)
                        .frame(height: 18)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .onChange(of: newTag) { newValue in
                            viewModel.calculateFilteredUncommonTags(text: newValue)
                        }
                    Spacer(minLength: 0)
                    Button {
                        viewModel.assignTagToArchive(tagNames: [newTag], completion: { status in
                            if status {
                                newTag = ""
                            }
                        })
                    } label: {
                        Image("PlusSign")
                            .frame(width: 40, height: 40)
                            .padding(.trailing, 4)
                    }
                }
            }
        }
    }
    
    var recentTags: some View {
        HStack {
            Text("Recent Tags - \(viewModel.addedTags.count) selected".uppercased())
                .textStyle(SmallXXXXXSemiBoldTextStyle())
                .foregroundColor(Color.middleGray)
            Spacer()
        }
    }
}


struct AddNewTagView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Nature",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Blue Sky",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    
    static var previews: some View {
        AddNewTagView(viewModel: AddNewTagViewModel(selectionTags: tags, selectedFiles: []))
    }
}
