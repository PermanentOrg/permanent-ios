//
//  FileViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FileViewModel {
    let thumbnail: String
    let name: String
    let date: String

    init(model: ChildItemVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT ?? "-"
        self.thumbnail = model.thumbURL500 ?? "-"
    }
}
