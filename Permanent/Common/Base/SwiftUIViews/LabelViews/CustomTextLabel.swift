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
        label.numberOfLines = 0
        label.attributedText = createAttributedText()
        label.textAlignment = .left
        if Constants.Design.isPhone {
            label.setTextSpacingBy(value: 15)
        }
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
