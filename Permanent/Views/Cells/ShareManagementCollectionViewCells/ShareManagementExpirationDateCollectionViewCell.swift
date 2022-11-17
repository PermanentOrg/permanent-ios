//
//  ShareManagementExpirationDateCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementExpirationDateCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementExpirationDateCollectionViewCell"
    
    @IBOutlet weak var expirationDateField: UITextField!
    @IBOutlet weak var detailsLabel: UILabel!
    
    var viewModel: ShareLinkViewModel?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expirationDateField.delegate = self
        
        expirationDateField.font = Text.style39.font
        expirationDateField.textColor = .darkBlue
        expirationDateField.backgroundColor = .whiteGray
        expirationDateField.clearButtonMode = .always
        
        detailsLabel.font = Text.style38.font
        detailsLabel.textColor = .middleGray
    }
    
    func configure(viewModel: ShareLinkViewModel) {
        self.viewModel = viewModel
        if let expiredDate = viewModel.shareVO?.expiresDT {
            expirationDateField.text = expiredDate.dateOnly
        }
        
        let placeholder = NSMutableAttributedString(string: "Expiration date (optional)".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkBlue])
        placeholder.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], range: (placeholder.string as NSString).range(of: "(optional)".localized()))
        expirationDateField.attributedPlaceholder = placeholder
        detailsLabel.text = "The link will disappear after the expiration date has been reached.".localized()
        setupDatePicker()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    func setupDatePicker() {
        let dateFormatter = DateFormatter()
        var date = dateFormatter.date(from: "")
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        date = dateFormatter.date(from: viewModel?.shareVO?.expiresDT ?? "")
        
        let datePicker = UIDatePicker()
        datePicker.date = date ?? Date()
        datePicker.addTarget(self, action: #selector(datePickerDidChange(_:)), for: .valueChanged)
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.sizeToFit()
        datePicker.minimumDate = Date()
        
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
        
        expirationDateField.inputView = stackView
    }
    
    @objc func datePickerDoneButtonPressed(_ sender: Any) {
        let dateFormatter = DateFormatter()
        var date = dateFormatter.date(from: "")
        dateFormatter.timeZone = .init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        date = dateFormatter.date(from: expirationDateField.text ?? "")
        if let date = date {
            let dateString: String? = dateFormatter.string(from: date)
            viewModel?.updateLinkWithChangedField(expiresDT: dateString, then: { [self] _, error in
                if error != nil {
                    expirationDateField.text = viewModel?.shareVO?.expiresDT
                }
            })
        } else {
            expirationDateField.text = viewModel?.shareVO?.expiresDT
        }
        
        expirationDateField.resignFirstResponder()
    }
    
    @objc func datePickerDidChange(_ sender: UIDatePicker) {
        let date = sender.date
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        expirationDateField.text = dateFormatter.string(from: date)
    }
}

extension ShareManagementExpirationDateCollectionViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        datePickerDoneButtonPressed(textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel?.updateLinkWithChangedField(expiresDT: "clear", then: { shareVO, _ in
            if shareVO != nil {
                self.expirationDateField.text = nil
            }
        })
        
        return false
    }
}
