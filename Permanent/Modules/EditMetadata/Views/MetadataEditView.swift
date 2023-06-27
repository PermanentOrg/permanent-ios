//
//  MetadataEditView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.06.2023.
//

import SwiftUI

struct MetadataEditView: View {
    var body: some View {
        CustomNavigationView {
            VStack {
                SectionView(
                    image: "photo",
                    title: "Editing 3 items",
                    rightButtonView: nil,
                    divider: Divider.init()
                )
                SectionView(
                    image: "metadataDescription",
                    title: "Description",
                    rightButtonView: RightButtonView(
                        text: "Enter Description",
                        action: { print("Description tapped")
                        }
                    )
                )
                SectionView(
                    image: "metadataTags",
                    title: "Tags",
                    rightButtonView: RightButtonView(
                        text: "Manage Tags",
                        action: { print("Manage Tags tapped") }
                    ),
                    divider: Divider.init()
                )
                SectionView(
                    image: "metadataFileNames",
                    title: "File names",
                    rightButtonView: RightButtonView(
                        text: "Modify",
                        action: { print("Modify tapped") }
                    ),
                    divider: Divider.init()
                )
                SectionView(
                    image: "metadataDateAndTime",
                    title: "Date and time",
                    rightButtonView: RightButtonView(
                        text: "Add",
                        action: { print("Add Date and Time tapped") }
                    ),
                    divider: Divider.init()
                )
                SectionView(
                    image: "metadataLocations",
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
        }
    }
}

struct MetadataEditView_Previews: PreviewProvider {
    static var previews: some View {
        MetadataEditView()
    }
}
