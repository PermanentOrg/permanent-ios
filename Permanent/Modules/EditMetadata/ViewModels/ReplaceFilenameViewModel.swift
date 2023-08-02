//
//  ReplaceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import Foundation

class ReplaceFilenameViewModel: ObservableObject {
    @Published var findText: String = ""
    @Published var replaceText: String = ""
}
