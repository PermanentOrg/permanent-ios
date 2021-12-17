//
//  FieldNameUI.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.12.2021.
//

import Foundation

enum FieldNameUI: String, CaseIterable {
 
    case archiveName, fullName, nickname = "profile.basic"
    case shortDescription = "profile.blurb"
    case longDescription = "profile.description"
    case emailAddress = "profile.email"
    case profileGender = "profile.gender"
    case birthDate, birthLocation = "profile.birth_info"
    
    var fieldToInsertString: String {
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
