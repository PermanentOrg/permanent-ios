//  
//  SortOption.swift
//  Permanent
//
//  Created by Adrian Creteanu on 16.11.2020.
//

import Foundation

enum SortOption: Int, CaseIterable {

    case nameAscending
    
    case nameDescending
    
    case dateAscending
    
    case dateDescending
    
    case typeAscending
    
    case typeDescending
    

    var title: String {
        switch self {
        case .dateAscending: return String.init(format: .sortOption, String.date, String.ascending)
        case .dateDescending: return String.init(format: .sortOption, String.date, String.descending)
        case .nameAscending: return String.init(format: .sortOption, String.name, String.ascending)
        case .nameDescending: return String.init(format: .sortOption, String.name, String.descending)
        case .typeAscending: return String.init(format: .sortOption, String.fileType, String.ascending)
        case .typeDescending: return String.init(format: .sortOption, String.fileType, String.descending)
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
}
