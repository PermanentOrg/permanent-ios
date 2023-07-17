//
//  AddNewTagView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.07.2023.

import SwiftUI

struct AddNewTagView: View {
    @ObservedObject var viewModel: AddNewTagViewModel
    @State private var newTag = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(viewModel: AddNewTagViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
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
                                Spacer(minLength: 0)
                                Button {
                                    
                                } label: {
                                    Image("PlusSign")
                                        .frame(width: 40, height: 40)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                        Spacer(minLength: 22)
                        HStack {
                            
                            Text("Recent Tags - <COUNT> selected".replacingOccurrences(of: "<COUNT>", with: "\(viewModel.allTags.count)").uppercased())
                                .textStyle(SmallXXXXXSemiBoldTextStyle())
                                .foregroundColor(Color.middleGray)
                            Spacer()
                        }
                        Spacer(minLength: 13)
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            AddTagsView(allTags: $viewModel.allTags)
                        }
                    }

                    .padding()
                    .navigationBarTitle("New Tag", displayMode: .inline)
                    .navigationBarItems(leading: Image("metadataTags")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24))
                }
            }
            VStack {
                Spacer()
                HStack {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
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
                        
                    } label: {
                        ZStack {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 48)
                                .background(Color(red: 0.07, green: 0.11, blue: 0.29))
                            Text("Add")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .frame(width: 146, alignment: .top)
                        }
                    }
                }
                .padding()
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .onAppear {
            viewModel.refreshTags()
            //viewModel.selectionTags = filesTags
            
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct AddNewTagView_Previews: PreviewProvider {
    @State static var tags: [TagVO] = [
        TagVO(tagVO: TagVOData(name: "Nature",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil)),
        TagVO(tagVO: TagVOData(name: "Blue Sky",status: "", tagId: 222, type: nil, createdDT: nil, updatedDT: nil))
    ]
    
    static var previews: some View {
        AddNewTagView(viewModel: AddNewTagViewModel(selectionTags: tags))
    }
}
