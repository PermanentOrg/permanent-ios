//
//  FieldNameUI.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.12.2021.
//

import Foundation

enum FieldNameUI: String, CaseIterable {
 
    case archiveName = "profile.basic"
    case shortDescription = "profile.blurb"
    case longDescription = "profile.description"
    case emailAddress = "profile.email"
    case profileGender = "profile.gender"
    
    var fieldToInsertString: String {
        switch self {
        case .archiveName, .shortDescription, .emailAddress, .profileGender: return "string1"
        case .longDescription: return "textData1"
        }
    }

}
