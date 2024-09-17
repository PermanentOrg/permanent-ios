//
//  AuthImageForRightSidePageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.09.2024.
import SwiftUI

struct AuthImageForRightSidePageView: View {
    let page: AuthContentType
    
    
    var body: some View {
        switch page {
        case .login:
            Rectangle()
                .foregroundColor(.clear)
                .background(
                    Image(.authLoginLeft)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
        default:
            Image(.none)
        }
    }
}
