//
//  AuthTextForRightSidePageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.09.2024.
import SwiftUI

struct AuthTextForRightSidePageView: View {
    let page: AuthContentType
    var isDescription: Bool = false
    
    var body: some View {
        switch page {
        case .login:
            if isDescription {
                Text("At Permanent, we celebrate our members' hard work through our public gallery and archive spotlights. Explore our gallery and, when you're ready, publish or share your own public archive!")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                    .lineSpacing(8)
            } else {
                Text("Haadsma Dairy Truck  |  The Haadsma Dairy Archive".uppercased())
                    .font(.custom("Usual-Regular", size: 10))
                    .kerning(1.6)
                    .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
            }
        default: Text("")
        }
    }
}
