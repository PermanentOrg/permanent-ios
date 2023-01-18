//  
//  TableViewData.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.11.2020.
//

import UIKit.UIColor

struct TableViewData {

    static let drawerData: [DrawerSection: [DrawerOption]] = [
        DrawerSection.navigationScreens: [
            DrawerOption.shares,
            DrawerOption.members
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
    
    static let allAccessRoles = AccessRole.allCases
        .map { $0.groupName }
    
    static let accessRoles = AccessRole.allCases
        .filter { $0 != .owner }
        .map { $0.groupName }
}

enum DrawerSection: Int {
    case navigationScreens
}
