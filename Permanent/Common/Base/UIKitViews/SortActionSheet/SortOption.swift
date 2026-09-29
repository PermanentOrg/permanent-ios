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
    
    /// The first order of each field, in menu order; picking a field starts there.
    static let fieldDefaults: [SortOption] = [.nameAscending, .dateDescending, .typeAscending]

    /// The mark between a title's field and its order, "  •  ".
    static let titleSeparator = String(format: .sortOption, "", "")

    /// A sort title as VoiceOver should read it, with a pause in place of the mark.
    static func spoken(_ title: String) -> String {
        title.replacingOccurrences(of: titleSeparator, with: ", ")
    }

    var title: String {
        return String(format: .sortOption, fieldTitle, directionTitle)
    }

    var spokenTitle: String {
        Self.spoken(title)
    }

    var fieldTitle: String {
        switch self {
        case .nameAscending, .nameDescending: return .name
        case .dateAscending, .dateDescending: return .date
        case .typeAscending, .typeDescending: return .sortFieldType
        }
    }

    var directionTitle: String {
        switch self {
        case .nameAscending: return .sortAToZ
        case .nameDescending: return .sortZToA
        case .dateAscending: return .sortOldestFirst
        case .dateDescending: return .sortNewestFirst
        case .typeAscending: return .sortAscending
        case .typeDescending: return .sortDescending
        }
    }

    /// Both orders of this option's field, in menu order.
    var fieldOrders: [SortOption] {
        switch self {
        case .nameAscending, .nameDescending: return [.nameAscending, .nameDescending]
        case .dateAscending, .dateDescending: return [.dateDescending, .dateAscending]
        case .typeAscending, .typeDescending: return [.typeAscending, .typeDescending]
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
