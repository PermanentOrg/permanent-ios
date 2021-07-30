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
        ],
        
        DrawerSection.others: [
            DrawerOption.members,
            DrawerOption.activityFeed,
            DrawerOption.invitations,
            DrawerOption.accountInfo,
            DrawerOption.security,
            DrawerOption.addStorage,
            DrawerOption.help,
            DrawerOption.logOut
        ]
    ]
}

struct StaticData {
    static let shareLinkButtonsConfig: [(title: String, bgColor: UIColor)] = [
        (.shareLink, .primary),
        (.linkSettings, .primary),
        (.revokeLink, .destructive)
    ]
    
    static let rolesTooltipData: [AccessRole: String] = [
        .owner: .ownerTooltipText,
        .manager: .managerTooltipText,
        .curator: .curatorTooltipText,
        .editor: .editorTooltipText,
        .contributor: .contributorTooltipText,
        .viewer: .viewerTooltipText
    ]
    
    static let accessRoles = AccessRole.allCases
        .filter { $0 != .owner }
        .map { $0.groupName }
}


struct SharedFileData {
    let fileName: String
    let date: String
    let thumbnailURL: String
    let archiveThumbnailURL: String
}
