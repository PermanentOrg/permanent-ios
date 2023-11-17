//
//  Chip.swift
//  ChipsApp
//
//  Created by Flaviu Silaghi on 01.11.2023.

import SwiftUI

struct EmailChip: View {
    let text: String
    let onDelete: (String) -> Void
    
    var body: some View {
        HStack {
            HStack {
                Text(text)
                    .textStyle(SmallXRegularTextStyle())
                    .foregroundColor(.darkBlue)
                Button {
                    onDelete(text)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 3)
        }
        .background(RoundedRectangle(cornerRadius: 4)
            .fill(Color.whiteGray))
    }
}
