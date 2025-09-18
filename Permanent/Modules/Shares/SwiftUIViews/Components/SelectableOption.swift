//
//  SelectableOption.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2025.
import SwiftUI

protocol SelectableOption {
    var title: String { get }
    var description: String { get }
    var icon: Image { get }
    var iconColor: Color { get }
}
