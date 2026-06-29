//
//  RedesignWidgetCard.swift
//  Permanent
//
//  Generic white card container: radius 24, Widget Drop shadow, clips content.
//  Padding is supplied by the caller so different cards can use their own.
//

import SwiftUI

struct RedesignWidgetCard<Content: View>: View {
    var cornerRadius: CGFloat = RedesignSpacing.cardRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .widgetDropShadow()
    }
}

#Preview {
    RedesignWidgetCard {
        Text("Card content")
            .padding(24)
    }
    .padding(24)
    .background(RedesignColor.whiteGray)
}
