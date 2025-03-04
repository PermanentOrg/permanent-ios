//
//  WarningBannerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import SwiftUI

/// A banner view that displays warning messages with a red background
/// Used to show important alerts or warning messages to the user
struct WarningBannerView: View {
    /// The warning message to display in the banner
    let message: String
    
    var body: some View {
        ZStack {
            // Light red background color for warning state
            Color(red: 1, green: 0.89, blue: 0.89)
            
            Text(message)
                .foregroundColor(Color(red: 0.7, green: 0.14, blue: 0.1)) // Dark red text color
                .font(.body)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
        }
        .frame(height: 72)
    }
} 
