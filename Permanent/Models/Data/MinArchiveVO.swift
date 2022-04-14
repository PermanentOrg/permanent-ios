//  
//  MinArchiveVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import Foundation

struct MinArchiveVO: Equatable, Codable {
    let name: String
    let thumbnail: String
    let shareStatus: String
    let shareId: Int
    let archiveID: Int
}
