//
//  FileDetailsDateCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 12.03.2021.
//

import UIKit

class FileDetailsDateCollectionViewCell: FileDetailsBaseCollectionViewCell {
    static let identifier = "FileDetailsDateCollectionViewCell"
    
    @IBOutlet weak var titleLabelField: UILabel!
    @IBOutlet weak var detailsTextField: UITextField!
    
    var date: Date?
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
        
        return dateFormatter
    }()
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func configure(withViewModel viewModel: FilePreviewViewModel, type: FileDetailsViewController.CellType) {
        super.configure(withViewModel: viewModel, type: type)
        
        titleLabelField.text = title
        titleLabelField.textColor = .white
        titleLabelField.font = Text.style9.font
        
        if let date = detailsDate() {
            detailsTextField.text = FileDetailsDateCollectionViewCell.dateFormatter.string(from: date)
        }
        
        detailsTextField.backgroundColor = .clear
        detailsTextField.textColor = .white
        detailsTextField.font = Text.style8.font
        detailsTextField.isUserInteractionEnabled = isEditable
        if isEditable {
            detailsTextField.backgroundColor = .darkGray
        }
        
        setupDatePicker()
    }
    
    func setupDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.date = date ?? Date()
        datePicker.addTarget(self, action: #selector(datePickerDidChange(_:)), for: .valueChanged)
        datePicker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.sizeToFit()
        
        let doneContainerView = UIView(frame: CGRect(x: 0, y: 0, width: datePicker.frame.width, height: 40))
        let doneButton = RoundedButton(frame: CGRect(x: datePicker.frame.width - 92, y: 0, width: 90, height: doneContainerView.frame.height))
        doneButton.autoresizingMask = [.flexibleLeftMargin]
        doneButton.setup()
        doneButton.setFont(UIFont.systemFont(ofSize: 17))
        doneButton.configureActionButtonUI(title: "done", bgColor: .systemBlue)
        doneButton.addTarget(self, action: #selector(datePickerDoneButtonPressed(_:)), for: .touchUpInside)
        doneContainerView.addSubview(doneButton)
        
        let stackView = UIStackView(arrangedSubviews: [datePicker, doneContainerView])
        stackView.axis = .vertical
        stackView.frame = CGRect(x: 0, y: 0, width: datePicker.frame.width, height: datePicker.frame.height + doneContainerView.frame.height + 40)
        
        detailsTextField.inputView = stackView
    }
    
    func detailsDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let date: Date?
        switch cellType {
        case .uploaded:
            date = dateFormatter.date(from: viewModel?.recordVO?.recordVO?.createdDT ?? "")
        case .lastModified:
            date = dateFormatter.date(from: viewModel?.recordVO?.recordVO?.updatedDT ?? "")
        case .date:
            date = dateFormatter.date(from: viewModel?.recordVO?.recordVO?.displayDT ?? "")
        case .created:
            date = dateFormatter.date(from: viewModel?.recordVO?.recordVO?.derivedDT ?? "")
        case .fileCreated:
            date = dateFormatter.date(from: viewModel?.recordVO?.recordVO?.derivedCreatedDT ?? "")
        default:
            date = nil
        }
        
        return date
    }
    
    @objc func datePickerDoneButtonPressed(_ sender: Any) {
        detailsTextField.resignFirstResponder()
    }
    
    @objc func datePickerDidChange(_ sender: UIDatePicker) {
        date = sender.date
        
        if let date = date {
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
            detailsTextField.text = dateFormatter.string(from: date)
        }
    }
}
