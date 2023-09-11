//
//  Text+Extension.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

extension Text {
    public func textStyle<Style: ViewModifier>(_ style: Style) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}
