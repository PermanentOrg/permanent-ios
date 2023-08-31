//
//  CustomAlertView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.08.2023.

import SwiftUI

/// Displays a simple two options alert with title and context
///  - Parameters:
///     - title: This is the tile of the alert
///     - context: The body of the alert
///     - confirmButtonText: The text of the confirm button
///     - confirmed: Will be a Binding<Bool> which will be set when confirm button is pressed
///  - Returns: Returns a view of a simple alert with two options as a View
struct CustomAlertView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var confirmed: Bool
    var title: String
    var context: String
    var confirmButtonText: String
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(title)
                    .textStyle(RegularBoldTextStyle())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.darkBlue)
                Text(context)
                    .textStyle(SmallXRegularTextStyle())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.darkBlue)
                    .frame(width: 216)
            }
            VStack(spacing: 8) {
                Button {
                    confirmed = true
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(confirmButtonText)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(CustomButtonStyle(backgroundColor: .darkBlue, foregroundColor: .white))
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(CustomButtonStyle(backgroundColor: .galleryGray, foregroundColor: .darkBlue))

            }
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background (
            Color.white
        )
        .cornerRadius(16)
    }
}

struct CustomAlertView_Previews: PreviewProvider {
    @State static var confirmed: Bool = false
    static var titleText = "Delete"
    static var context = "Are you sure you want to delete the selected files?"
    static var confirmButtonText = "Delete files"
    
    static var previews: some View {
        CustomAlertView(confirmed: $confirmed, title: titleText, context: context, confirmButtonText: confirmButtonText)
    }
}
