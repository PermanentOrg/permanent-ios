//
//  ProfileItemType.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.12.2021.
//

enum ProfileItemType: String, CaseIterable {
    case archiveName
    case shortDescription
    case longDescription
    case emailAddress
    case profileGender
    case fullName
    case nickname
    case birthDate
    case birthLocation
    
    var itemTypeToString: String {
        switch self {
        case .archiveName, .shortDescription, .emailAddress, .profileGender: return "string1"
        case .longDescription: return "textData1"
        case .fullName: return "string2"
        case .nickname: return "string3"
        case .birthDate: return "day1"
        case .birthLocation: return "LocnVOs"
        }
    }
}

