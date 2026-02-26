//
//  FindArchiveByEmailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

struct FindArchiveByEmailView: View {
    @ObservedObject var viewModel: ShareItemViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(height: 64)
                .background(Color.white)

            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                .background(Color.blue50)

            VStack(alignment: .leading, spacing: 16) {
                Text("Find an archive using email address")
                    .font(.custom("Usual-Medium", size: 16))
                    .foregroundColor(Color.blue900)

                Text("This screen is ready for the search form implementation.")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(Color.blue600)

                Spacer()
            }
            .padding(24)

            Spacer(minLength: 0)
        }
        .background(Color.white)
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: {
                    viewModel.closeFindArchiveByEmail()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.blue900)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                Spacer()
            }

            Text("Find archive")
                .font(.custom("Usual-Medium", size: 16))
                .foregroundColor(Color.blue900)

            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(.closeButtonV2)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
            }
        }
    }
}
