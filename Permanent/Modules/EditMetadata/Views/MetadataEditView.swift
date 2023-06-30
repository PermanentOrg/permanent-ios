//
//  MetadataEditView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.06.2023.
//

import SwiftUI

struct MetadataEditView: View {
    @ObservedObject var viewModel: FilesMetadataViewModel
    @State var inputText: String = ""
    
    init(viewModel: FilesMetadataViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        CustomNavigationView {
            VStack {
                SectionView(
                    imageUrl: viewModel.selectedFiles.first?.thumbnailURL500,
                    title: "Editing \(Int(viewModel.selectedFiles.count)) items",
                    rightButtonView: nil,
                    divider: Divider.init()
                )
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
                            TextView(text: $inputText, viewModel: viewModel, textStyle: TextFontStyle.style39, textColor: .middleGray)
                                .padding(.all, 5)
                                .frame(maxHeight: 72)
                        }
                        .frame(height: 72)
                        .foregroundColor(.clear)
                    }
                }
                SectionView(
                    assetName: "metadataTags",
                    title: "Tags",
                    rightButtonView: RightButtonView(
                        text: "Manage Tags",
                        action: { print("Manage Tags tapped") }
                    ),
                    divider: Divider.init()
                )
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
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationBarTitle("Edit Files Metadata")
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea()
            .background(Color.whiteGray)
            .onTapGesture {
                dismissKeyboard()
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
