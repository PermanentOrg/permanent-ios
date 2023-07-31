//
//  CustomSegmentedControl.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.07.2023.

import SwiftUI

struct CustomSegmentedControl: View {
    @Binding var selectedItem: MenuItem?
    let items: [MenuItem]

    var body: some View {
        ZStack{
            HStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    Button(action: {
                        self.selectedItem = item
                    }) {
                        VStack(spacing: 5) {
                            Image(uiImage: item.image.withRenderingMode(.alwaysTemplate))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(item.name.uppercased())
                                .kerning(1)
                                .textStyle(SmallXXXXXSemiBoldTextStyle())
                                .multilineTextAlignment(.center)
                        }
                        .padding(.all, 10)
                        .foregroundColor(.darkBlue)
                        .opacity(self.selectedItem == item ? 1 : 0.5)
                        .cornerRadius(8)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(self.selectedItem == item ? Color(red: 0.96, green: 0.96, blue: 0.99) : Color.white)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .cornerRadius(4)
            .overlay(
            RoundedRectangle(cornerRadius: 4)
            .inset(by: -1)
            .stroke(Color(red: 0.96, green: 0.96, blue: 0.99), lineWidth: 1)
            )
        }
    }
}

struct CustomSegmentedControl_Previews: PreviewProvider {
    static var previews: some View {
        MetadataEditFileNames(viewModel: MetadataEditFileNamesViewModel(selectedFiles: []))
    }
}
