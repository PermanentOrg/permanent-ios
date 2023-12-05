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
    @Published var changesWereSaved: Bool = false
    @Published var showAlert: Bool = false
    
    let startingDate: Date = Calendar.current.date(from: DateComponents(year: 1900)) ?? Date()
    let endingDate: Date = Date()
    
    init(selectedFiles: [FileModel], hasUpdates: Binding<Bool>) {
        self.selectedFiles = selectedFiles
        self.hasUpdates = hasUpdates
        
        selectedDate = getCommonDate()
    }
    
    func getCommonDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var dates = [Date]()
        for file in selectedFiles {
            if let date = dateFormatter.date(from: file.createdDT ?? "") {
                dates.append(date)
            }
        }
        
        // Check if all dates are the same
        let uniqueDates = Set(dates)
        if uniqueDates.count == 1 {
            // If all dates are the same, return the common date
            return uniqueDates.first ?? Date()
        } else {
            // If dates are different, return the current date
            return Date()
        }
    }
    
    func applyChanges() {
        isLoading = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = dateFormatter.string(from: selectedDate)
        
        let updatedFiles = selectedFiles.map { file in
            var newFile = file
            newFile.date = date
            return newFile
        }
        
        let apiOperation = APIOperation(FilesEndpoint.multipleFilesUpdate(files: updatedFiles))
        
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .json( _, _):
                    self?.hasUpdates.wrappedValue = true
                    self?.changesWereSaved = true
                case .error(_, _):
                    self?.showAlert = true
                default:
                    self?.showAlert = true
                }
            }
        }
    }
}
