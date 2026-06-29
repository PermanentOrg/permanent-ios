//
//  RedesignPrimaryButton.swift
//  Permanent
//
//  Dark-blue gradient pill button: height 56, radius 12, padding h32 v8.
//  Label is Usual Medium 14 / lineHeight 24, white. Shows a spinner + disables
//  while `isLoading`.
//

import SwiftUI

struct RedesignPrimaryButton: View {
    let title: String
    var gradient: LinearGradient = RedesignGradient.primaryButtonC
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: { if !isLoading { action() } }) {
            ZStack {
                Text(title)
                    .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                    .foregroundColor(.white)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: RedesignSpacing.buttonHeight)
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: RedesignSpacing.buttonRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        RedesignPrimaryButton(title: "Create your first Archive") {}
        RedesignPrimaryButton(title: "Create Archive", gradient: RedesignGradient.primaryButtonD) {}
        RedesignPrimaryButton(title: "Creating…", gradient: RedesignGradient.primaryButtonD, isLoading: true) {}
    }
    .padding(24)
    .background(RedesignColor.whiteGray)
}
