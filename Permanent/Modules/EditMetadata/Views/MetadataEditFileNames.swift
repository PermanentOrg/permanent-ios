//
//  MetadataEditFileNames.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2023.

import SwiftUI

struct MenuItem: Hashable {
    var name: String
    var image: UIImage
}

struct MetadataEditFileNames: View {
    @ObservedObject var viewModel: MetadataEditFileNamesViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var selectedItem: MenuItem? = MenuItem(name: "Replace", image: UIImage(named: "metadataReplace")!)
    private var menuItems: [MenuItem] = [
        MenuItem(name: "Replace", image: UIImage(named: "metadataReplace")!),
        MenuItem(name: "Append", image: UIImage(named: "metadataAppend")!),
        MenuItem(name: "Sequence", image: UIImage(named: "metadataSequence")!),
    ]

    init(viewModel: MetadataEditFileNamesViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    CustomSegmentedControl(selectedItem: $selectedItem, items: menuItems)
                    Spacer()
                }
                .padding()
                .navigationBarTitle("Edit file names", displayMode: .inline)
                .navigationBarItems(leading: Image("editFilenames")
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24))
            }
        }
    }
}

struct MetadataEditFileNames_Previews: PreviewProvider {
    static var previews: some View {
        MetadataEditFileNames(viewModel: MetadataEditFileNamesViewModel(selectedFiles: []))
    }
}
