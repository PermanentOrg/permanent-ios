//
//  SectionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.06.2023.

import SwiftUI

struct SectionView: View {
    let image: String
    let title: String
    let rightButtonView: RightButtonView?
    var divider: Divider? = nil

    var body: some View {
        VStack {
            HStack {
                Image(image)
                Text(title)
                Spacer()
                rightButtonView
            }

            divider
            .padding(.top, 24)
        }
        .padding(.top, 24)
    }
}

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        SectionView(image: "metadataDescription", title: "Your text here", rightButtonView: RightButtonView(text: "Right Side", action: {
        }))
    }
}
