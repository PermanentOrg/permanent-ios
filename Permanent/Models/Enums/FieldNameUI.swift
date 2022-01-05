//
//  FieldNameUI.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.12.2021.
//

enum FieldNameUI: String, CaseIterable {
    
    case basic = "profile.basic"
    case blurb = "profile.blurb"
    case description = "profile.description"
    case email = "profile.email"
    case profileGender = "profile.gender"
    case birthInfo = "profile.birth_info"
}

struct FieldType {
    var shortDescription: String
    var longDescription: String
    var fullName: String
    var nickname: String
    var gender: String
    var birthDate: String
    var birthLocation: String
}
