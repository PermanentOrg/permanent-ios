//  
//  TableViewData.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.11.2020.
//

import UIKit.UIColor

struct TableViewData {

    static let drawerData: [DrawerSection: [DrawerOption]] = [
        DrawerSection.files: [
            DrawerOption.files,
            DrawerOption.shares
            
            //DrawerOption(icon: .folder, title: .myFiles, isSelected: true),
            //DrawerOption(icon: .share, title: .shares, isSelected: false),
            //DrawerOption(icon: .public, title: .public, isSelected: false)
        ],
        
        DrawerSection.others: [
            //DrawerOption(icon: .relationships, title: .relationships, isSelected: false),
            //DrawerOption(icon: .group, title: .members, isSelected: false),
            //DrawerOption(icon: .power, title: .apps, isSelected: false),
            //DrawerOption(icon: .power, title: .logOut, isSelected: false),
            
            DrawerOption.logOut
        ]
    ]
}

struct StaticData {
    static let shareLinkButtonsConfig: [(title: String, bgColor: UIColor)] = [
        (.copyLink, .primary),
        (.manageLink, .primary),
        (.revokeLink, .destructive)
    ]
}


struct SharedFileData {
    let fileName: String
    let date: String
    let thumbnailURL: String
    let archiveThumbnailURL: String
}
