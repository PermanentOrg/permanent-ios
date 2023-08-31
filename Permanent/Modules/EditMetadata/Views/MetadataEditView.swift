//
//  MetadataEditView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.06.2023.
//

import SwiftUI

struct MetadataEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: FilesMetadataViewModel

    @State var showAddNewTag: Bool = false
    @State var showEditFilenames: Bool = false
    @State var showSetLocation: Bool = false
    @State var removeTagName: String? = nil
    @State var reloadFiles: Bool = false
    var dismissAction: ((Bool) -> Void)?
    
    var body: some View {
        CustomNavigationView(content: {
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
                            VStack(alignment: .leading) {
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
                                if viewModel.haveDiffDescription {
                                    Text("Some files already have description!")
                                        .textStyle(SmallXXRegularTextStyle())
                                        .foregroundColor(.lightRed)
                                        .padding(.top, 5)
                                    Divider()
                                        .padding(.top, 0)
                                }
                            }
                        }
                        Group {
                            SectionView(
                                assetName: "metadataTags",
                                title: "Tags",
                                rightButtonView: RightButtonView(
                                    text: "Apply all to selection",
                                    showChevron: false,
                                    action: {
                                        viewModel.assignAllTagsToAll()
                                    }
                                ),
                                haveRightSection: viewModel.havePartialTags
                            )
                            .padding(.top, -10)
                            TagsView(viewModel: viewModel, showAddNewTagView: $showAddNewTag)
                            Spacer(minLength: 24)
                            Divider()
                        }
                        SectionView(
                            assetName: "metadataFileNames",
                            title: "File names",
                            rightButtonView: RightButtonView(
                                text: "Modify",
                                action: {
                                    showEditFilenames.toggle()
                                }
                            ),
                            divider: Divider.init()
                        )
                        SectionView(
                            assetName: "metadataDateAndTime",
                            title: "Date and time",
                            rightButtonView: RightButtonView(
                                text: "Add",
                                action: {
                                    
                                }
                            ),
                            divider: Divider.init()
                        )
                        SectionView(
                            assetName: "metadataLocations",
                            title: viewModel.locationSectionText,
                            rightButtonView: RightButtonView(
                                text: "Add",
                                action: {
                                    showSetLocation.toggle()
                                }
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
            .sheet(isPresented: $showEditFilenames) {
                MetadataEditFileNamesView(viewModel: MetadataEditFileNamesViewModel(selectedFiles: viewModel.selectedFiles, hasUpdates: $viewModel.hasUpdates))
            }
            .sheet(isPresented: $showSetLocation) {
                AddLocationView(viewModel: AddLocationViewModel(selectedFiles: viewModel.selectedFiles))
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
            .onChange(of: showEditFilenames) { newValue in
                if newValue == false {
                    self.reloadFiles = false
                    viewModel.refreshFiles()
                }
            }
            .onChange(of: showSetLocation) { newValue in
                if newValue == false {
                    self.reloadFiles = false
                    viewModel.refreshFiles()
                }
            }
        }, leftButton: {
            Button(action: {
                dismissAction?(viewModel.hasUpdates)
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        })
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
