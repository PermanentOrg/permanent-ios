//
//  BannerView.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 29.05.2023.

import SwiftUI

struct BannerViewSwiftUI: View {
    
    var action: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Legacy Planning")
                .foregroundColor(.white)
                .font(.headline)
            Text("Your Legacy Plan will determine when, how, and with whom your materials will be shared.")
                .foregroundColor(.white)
                .font(.footnote)
                
            Divider()
            
            Button("Try now") {
                action?()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color("DarkBlue")
                    )
        )
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        BannerViewSwiftUI()
    }
}
