//
//  RedesignGreetingRow.swift
//  Permanent
//
//  Greeting row (Frames B/C): gradient-person avatar + "Hello, {name} 👋"
//  + "Your memories are safe here!".
//

import SwiftUI

struct RedesignGreetingRow: View {
    let firstName: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 48×48 white circle with a purple→orange person.fill (103°).
            ZStack {
                Circle()
                    .fill(Color.white)
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(RedesignGradient.iconPurpleOrange)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 0) {
                Text("Hello, \(firstName) 👋")
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 16))
                    .tracking(-0.16)
                    .foregroundColor(RedesignColor.darkBlue)
                    .frame(height: 24)

                Text("Your memories are safe here!")
                    .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                    .foregroundColor(RedesignColor.blue600)
                    .frame(height: 24)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RedesignGreetingRow(firstName: "Robert")
        .padding(24)
        .background(RedesignColor.whiteGray)
}
