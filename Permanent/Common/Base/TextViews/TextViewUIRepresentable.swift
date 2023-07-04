//
//  TextViewUIRepresentable.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.06.2023.

import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var didSaved: Bool
    var viewModel: FilesMetadataViewModel
    var textStyle: TextStyle = TextFontStyle.style
    var textColor: UIColor = .black
    
    func makeUIView(context: UIViewRepresentableContext<TextView>) -> UITextView {
        let textView = UITextView()
        textView.font = textStyle.font
        textView.textColor = textColor
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<TextView>) {
        uiView.text = text
        uiView.textColor = textColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator : NSObject, UITextViewDelegate {
        var parent: TextView

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.viewModel.saveDescription(textView.text)
            parent.didSaved = true
        }
    }
}
