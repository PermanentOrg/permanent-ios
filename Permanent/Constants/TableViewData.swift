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
            DrawerOption(icon: .folder, title: .myFiles, isSelected: true),
            DrawerOption(icon: .share, title: .shares, isSelected: false),
            DrawerOption(icon: .public, title: .public, isSelected: false)
        ],
        
        DrawerSection.others: [
            DrawerOption(icon: .relationships, title: .relationships, isSelected: false),
            DrawerOption(icon: .group, title: .members, isSelected: false),
            DrawerOption(icon: .power, title: .apps, isSelected: false),
        ]
    ]
    
    
}

struct StaticData {
    static let shareLinkButtonsConfig: [(title: String, bgColor: UIColor)] = [
        ("Copy link", .primary),
        ("Manage link", .primary),
        ("Revoke link", .destructive)
    ]
}

