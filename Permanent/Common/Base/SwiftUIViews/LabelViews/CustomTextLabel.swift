//
//  CustomTextLabel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.06.2024.

import SwiftUI

struct CustomTextLabel: UIViewRepresentable {
    var preText: String
    var boldText: String
    var postText: String
    var preAndPostTextFont: UIFont
    var boldTextFont: UIFont
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0  // Allow multiple lines if needed
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.attributedText = createAttributedText()
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = createAttributedText()
    }
    
    private func createAttributedText() -> NSAttributedString {
        let preAttributedText = NSAttributedString(string: preText, attributes: [.foregroundColor: UIColor.white, .font: preAndPostTextFont])
        let boldAttributedText = NSAttributedString(string: boldText, attributes: [.foregroundColor: UIColor.white, .font: boldTextFont])
        let postAttributedText = NSAttributedString(string: postText, attributes: [.foregroundColor: UIColor.white, .font: preAndPostTextFont])
        
        let combinedText = NSMutableAttributedString()
        combinedText.append(preAttributedText)
        combinedText.append(boldAttributedText)
        combinedText.append(postAttributedText)
        
        return combinedText
    }
}

struct CustomTextView: View {
    var preText: String
    var boldText: String
    var postText: String
    var preAndPostTextFont: UIFont
    var boldTextFont: UIFont
    
    @State private var intrinsicContentSize: CGSize = .zero

    var body: some View {
        CustomTextLabel(
            preText: preText,
            boldText: boldText,
            postText: postText,
            preAndPostTextFont: preAndPostTextFont,
            boldTextFont: boldTextFont
        )
        .background(ViewGeometry())
        .frame(height: intrinsicContentSize.height)
        .onPreferenceChange(HeightPreferenceKey.self) { value in
            self.intrinsicContentSize.height = value
        }
    }
}

struct ViewGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: Value = 0

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}
