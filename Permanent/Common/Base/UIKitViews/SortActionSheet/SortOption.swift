//  
//  SortOption.swift
//  Permanent
//
//  Created by Adrian Creteanu on 16.11.2020.
//

import Foundation

enum SortOption: Int, CaseIterable, Codable {

    case nameAscending
    
    case nameDescending
    
    case dateAscending
    
    case dateDescending
    
    case typeAscending
    
    case typeDescending
    
    var title: String {
        switch self {
        case .dateAscending: return String(format: .sortOption, String.date, "(\(String.oldest))")
        case .dateDescending: return String(format: .sortOption, String.date, "(\(String.newest))")
        case .nameAscending: return String(format: .sortOption, String.name, String.aToZ)
        case .nameDescending: return String(format: .sortOption, String.name, String.zToA)
        case .typeAscending: return String(format: .sortOption, String.fileType, String.arrowUpCharacter)
        case .typeDescending: return String(format: .sortOption, String.fileType, String.arrowDownCharacter)
        }
    }
    
    var apiValue: String {
        switch self {
        case .dateAscending: return "sort.display_date_asc"
        case .dateDescending: return "sort.display_date_desc"
        case .nameAscending: return "sort.alphabetical_asc"
        case .nameDescending: return "sort.alphabetical_desc"
        case .typeAscending: return "sort.type_asc"
        case .typeDescending: return "sort.type_desc"
        }
    }

    var stelaValue: String {
        switch self {
        case .dateAscending: return "date-ascending"
        case .dateDescending: return "date-descending"
        case .nameAscending: return "alphabetical-ascending"
        case .nameDescending: return "alphabetical-descending"
        case .typeAscending: return "type-ascending"
        case .typeDescending: return "type-descending"
        }
    }

    private static let byServerValue: [String: SortOption] = Dictionary(
        uniqueKeysWithValues: allCases.flatMap { [($0.apiValue, $0), ($0.stelaValue, $0)] }
    )

    init?(serverValue: String?) {
        guard let value = serverValue, let match = SortOption.byServerValue[value] else { return nil }
        self = match
    }
}
