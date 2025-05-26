//
//  ChecklistCongratsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.05.2025.

import Foundation
import SwiftUI

class ChecklistOptionsViewModel: ObservableObject {
    @Published var items: [ChecklistItem]
    @Published var completionPercentage: Int
    @Published var redraw: UUID
    @Published var showsChecklistButton: Bool
    
    init(items: [ChecklistItem], completionPercentage: Int, showsChecklistButton: Bool) {
        self.items = items
        self.completionPercentage = completionPercentage
        self.redraw = UUID()
        self.showsChecklistButton = showsChecklistButton
    }
    
    func handleItemTap(_ item: ChecklistItem) {
        guard let type = item.type else { return }
        
        switch type {
        case .archiveCreated:
            break
        case .storageRedeemed:
            ChecklistCoordinator.shared.presentStorageRedeem()
        case .legacyContact:
            ChecklistCoordinator.shared.presentLegacyContact()
        case .archiveSteward:
            ChecklistCoordinator.shared.presentArchiveSteward()
        case .archiveProfile:
            break
        case .firstUpload:
            break
        case .publishContent:
            break
        }
    }
} 
