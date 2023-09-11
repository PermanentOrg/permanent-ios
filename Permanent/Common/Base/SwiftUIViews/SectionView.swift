//
//  SectionView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.06.2023.

import SwiftUI
import SDWebImageSwiftUI

struct SectionView: View {
    var assetName: String = ""
    let title: String
    var rightButtonView: RightButtonView?
    var haveRightSection: Bool = true
    var divider: Divider? = nil
    
    var body: some View {
        VStack {
            HStack {
                Image(assetName)
                Text(title)
                    .textStyle(SmallRegularTextStyle())
                Spacer()
                if haveRightSection {
                    rightButtonView
                }
            }
            divider
                .padding(.top, 24)
        }
        .padding(.top, 24)
    }
}

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        SectionView(title: "Your text here", rightButtonView: RightButtonView(text: "Right Side", action: {
        }))
    }
}
