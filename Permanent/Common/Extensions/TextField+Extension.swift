//
//  TextField+Extension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.04.2024.

import SwiftUI

extension TextField {
    public func textStyle<Style: ViewModifier>(_ style: Style) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}

