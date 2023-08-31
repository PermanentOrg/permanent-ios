//
//  EditDateAndTimeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.08.2023.

import SwiftUI

class EditDateAndTimeViewModel: ObservableObject {
    var selectedFiles: [FileModel]
    var hasUpdates: Binding<Bool>
    
    @Published var isLoading: Bool = false
    @Published var changesConfirmed: Bool = false
    @Published var selectedDate = Date()
    @Published var showConfirmation:Bool = false
    
    let startingDate: Date = Calendar.current.date(from: DateComponents(year: 1900)) ?? Date()
    let endingDate: Date = Date()
    
    init(selectedFiles: [FileModel], hasUpdates: Binding<Bool>) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
    }
    
    func applyChanges() {
        ///To do: Implement date change
    }
}
