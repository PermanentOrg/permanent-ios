//
//  FolderSortViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderSortViewModel: ViewModelInterface {
    static let didUpdateSortingOptionNotification = Notification.Name("FolderSortViewModel.didUpdateSortingOptionNotification")
    
    var sortingOption: SortOption = .nameAscending {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateSortingOptionNotification, object: self, userInfo: nil)
        }
    }
}
