//
//  RightButtonView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.06.2023.
//

import SwiftUI

struct RightButtonView: View {
    let text: String
    var showChevron: Bool
    let action: () -> Void
    
    init(text: String, showChevron: Bool = true, action: @escaping () -> Void) {
        self.text = text
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(text)
                    .textStyle(SmallSemiBoldTextStyle())
                if showChevron {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(.darkBlue)
        }
    }
}

struct RightButtonView_Previews: PreviewProvider {
    static var previews: some View {
        RightButtonView(text: "Your text here") {
            
        }
    }
}
