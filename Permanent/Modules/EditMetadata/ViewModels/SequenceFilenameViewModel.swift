//
//  SequenceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class SequenceFilenameViewModel: ObservableObject, MetadataEditFilenamesProtocol {
    @Published var isSelectingFormat: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var isSelectingWhere: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var isSelectingAdditionalData: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var selectedFormatOptions: PullDownItem?
    @Published var selectedWhereOptions: PullDownItem?
    @Published var selectedAdditionalOption: PullDownItem?
    @Published var baseText: String = ""
    @Published var startNumberText: String = "1" {
        didSet {
            updatePreview()
        }
    }
    
    var fileNamePreview: Binding<String?>
    var selectedFiles: [FileModel]
    var filteredFiles: [FileModel] = []
    var whereOptions = [
        PullDownItem(title: "Before name"),
        PullDownItem(title: "After name")
    ]
    var formatOptions = [
        PullDownItem(title: "Date & Time"),
        PullDownItem(title: "Count")
    ]
    var additionalOptions: [PullDownItem] = [
        PullDownItem(title: "Created"),
        PullDownItem(title: "Last modified"),
        PullDownItem(title: "Uploaded")
    ]
    var selectionWillUpdate: Bool = false
    
    static let displayDateFormatter: DateFormatter = {
        let displayDateFormatter = DateFormatter()
        displayDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        return displayDateFormatter
    }()
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
        
    }
    
    func getSelectedFiles() -> [FileModel] {
        guard baseText.isNotEmpty else {
            return []
        }
        
        var fileNumber = 0
        let filteredFiles = selectedFiles.map { file in
            var newFile = file
            if selectedFormatOptions?.title == "Count" {
                if selectedWhereOptions?.title == "Before name" {
                    newFile.name = String("\(calculateZeros(currentFile: fileNumber + 1))\(fileNumber + (Int(startNumberText) ?? 0))\(baseText)")
                } else {
                    newFile.name = String("\(baseText)\(calculateZeros(currentFile: fileNumber + 1))\(fileNumber + (Int(startNumberText) ?? 0))")
                }
                fileNumber += 1
            } else {
                var file = selectedFiles.first
                var formattedDate: String = ""
                
                if let date = dateDetails(file: file) {
                    formattedDate = SequenceFilenameViewModel.displayDateFormatter.string(from: date)
                }
                
                if selectedWhereOptions?.title == "Before name" {
                    newFile.name = String("\(formattedDate)\(baseText)")
                } else {
                    newFile.name = String("\(baseText)\(formattedDate)")
                }
            }
            return newFile
        }
        return filteredFiles
    }
    
    func updatePreview() {
        var fileName = selectedFiles.first?.name ?? ""
        guard baseText.isNotEmpty else {
            fileNamePreview.wrappedValue = fileName
            return
        }
        
        if selectedFormatOptions?.title == "Count" {
            
            if selectedWhereOptions?.title == "Before name" {
                fileName = String("\(calculateZeros(currentFile: 1))\(startNumberText)\(baseText)")
            } else {
                fileName = String("\(baseText)\(calculateZeros(currentFile: 1))\(startNumberText)")
            }
        } else {
            var file = selectedFiles.first
            var formattedDate: String = ""
            
            if let date = dateDetails(file: file) {
                formattedDate = SequenceFilenameViewModel.displayDateFormatter.string(from: date)
            }
            
            if selectedWhereOptions?.title == "Before name" {
                fileName = String("\(baseText)\(formattedDate)")
            } else {
                fileName = String("\(formattedDate)\(baseText)")
            }
        }
        fileNamePreview.wrappedValue = fileName
    }
    
    func dateDetails(file: FileModel?) -> Date? {
        let date: Date?
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        switch selectedAdditionalOption?.title {
        case "Created":
            date = dateFormatter.date(from: file?.createdDT ?? "")
        case "Last modified":
            date = dateFormatter.date(from: file?.modifiedDT ?? "")
        case "Uploaded":
            date = dateFormatter.date(from: file?.uploadedDT ?? "")
        default:
            date = dateFormatter.date(from: "")
        }
        return date
    }
    
    func calculateZeros(currentFile: Int) -> String {
        let startingNumber = Int(startNumberText) ?? 1
        let totalFiles = selectedFiles.count
        
        let maxNumber = startingNumber + totalFiles - 1
        let maxDigits = String(maxNumber).count
        
        let currentNumber = startingNumber + currentFile - 1
        let currentDigits = String(currentNumber).count
        let zerosToAdd = String(repeating: "0", count: maxDigits - currentDigits)
        
        return zerosToAdd
    }
}

