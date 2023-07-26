//
//  MetadataEditView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.06.2023.
//

import SwiftUI

struct MetadataEditView: View {
    @ObservedObject var viewModel: FilesMetadataViewModel
    @State var showAddNewTag: Bool = false
    @State var removeTagName: String? = nil
    @State var reloadFiles: Bool = false
    
    init(viewModel: FilesMetadataViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        CustomNavigationView {
            ZStack {
                Color.whiteGray
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        Group {
                            SectionHeaderView(selectedFiles: $viewModel.selectedFiles)
                            Divider()
                                .padding(.horizontal, 0)
                                .padding(.top, 24)
                        }
                        Group {
                            VStack {
                                SectionView(
                                    assetName: "metadataDescription",
                                    title: "Description",
                                    rightButtonView: RightButtonView(
                                        text: "Enter Description",
                                        action: { print("Description tapped") }
                                    ),
                                    haveRightSection: false
                                )
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2)
                                                .inset(by: 0.5)
                                                .stroke(Color.galleryGray, lineWidth: 1)
                                        )
                                    TextView(text: $viewModel.inputText,
                                             didSaved: $viewModel.didSaved,
                                             textStyle: TextFontStyle.style39,
                                             textColor: .middleGray)
                                        .padding(.all, 5)
                                        .frame(maxHeight: 72)
                                }
                                .frame(height: 72)
                                .foregroundColor(.clear)
                            }
                        }
                        Group {
                            SectionView(
                                assetName: "metadataTags",
                                title: "Tags",
                                rightButtonView: RightButtonView(
                                    text: "Manage Tags",
                                    action: { print("Manage Tags tapped") }
                                ),
                                haveRightSection: false
                            )
                            TagsView(viewModel: viewModel, showAddNewTagView: $showAddNewTag)
                            Divider()
                        }
                        SectionView(
                            assetName: "metadataFileNames",
                            title: "File names",
                            rightButtonView: RightButtonView(
                                text: "Modify",
                                action: { print("Modify tapped") }
                            ),
                            divider: Divider.init()
                        )
                        SectionView(
                            assetName: "metadataDateAndTime",
                            title: "Date and time",
                            rightButtonView: RightButtonView(
                                text: "Add",
                                action: { print("Add Date and Time tapped") }
                            ),
                            divider: Divider.init()
                        )
                        SectionView(
                            assetName: "metadataLocations",
                            title: "Locations",
                            rightButtonView: RightButtonView(
                                text: "Add",
                                action: { print("Add Location tapped") }
                            )
                        )
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .navigationBarTitle("Edit Files Metadata", displayMode: .inline)
                    .navigationBarBackButtonHidden(true)
                    .ignoresSafeArea()
                    .background(Color.whiteGray)
                    .onTapGesture {
                        dismissKeyboard()
                    }
                }
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                        viewModel.showAlert = false
                    })
                }
            }
            .sheet(isPresented: $showAddNewTag) {
                AddNewTagView(viewModel: AddNewTagViewModel(selectionTags: viewModel.allTags, selectedFiles: viewModel.selectedFiles))
            }
            .onAppear {
                viewModel.refreshFiles()
            }
            .onChange(of: showAddNewTag) { newValue in
                if newValue == false {
                    self.reloadFiles = false
                    viewModel.refreshFiles()
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MetadataEditView_Previews: PreviewProvider {
    static var previews: some View {
        MetadataEditView(viewModel: FilesMetadataViewModel(files: []))
    }
}
