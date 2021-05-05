//
//  FileDetailsBaseCollectionViewCell.swift
//  Permanent
//
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit

class FileDetailsBaseCollectionViewCell: UICollectionViewCell {
    
    var viewModel: FilePreviewViewModel?
    var cellType: FileDetailsViewController.CellType?
    
    var title: String {
        switch cellType {
        case .name:
            return "Name".localized()
        case .description:
            return "Description".localized()
        case .date:
            return "Date".localized()
        case .location:
            return "Location".localized()
        case .tags:
            return "Tags".localized()
        case .uploaded:
            return "Uploaded".localized()
        case .lastModified:
            return "Last Modified".localized()
        case .created:
            return "Created".localized()
        case .fileCreated:
            return "File Created".localized()
        case .size:
            return "Size".localized()
        case .fileType:
            return "File Type".localized()
        case .originalFileName:
            return "Original File Name".localized()
        case .originalFileType:
            return "Original File Type".localized()
        default: return ""
        }
    }
    
    var isEditable: Bool {
        let editableTypes: [FileDetailsViewController.CellType] = [.name, .description, .date, .location, .tags]
        if let cellType = cellType {
            return (viewModel?.isEditable ?? false) && editableTypes.contains(cellType)
        } else {
            return false
        }
    }
    
    func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        self.viewModel = viewModel
        self.cellType = type
    }
    
}
