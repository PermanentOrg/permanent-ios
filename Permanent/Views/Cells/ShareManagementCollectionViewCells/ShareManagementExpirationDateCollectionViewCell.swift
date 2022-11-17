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
    
    var expiredDate: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        expirationDateField.font = Text.style39.font
        expirationDateField.textColor = .darkBlue
        expirationDateField.backgroundColor = .whiteGray
        
        detailsLabel.font = Text.style38.font
        detailsLabel.textColor = .middleGray
    }
    
    func configure(expiredDateValue: String?) {
        if let expiredDate = expiredDateValue {
            self.expiredDate = expiredDate
            expirationDateField.text = expiredDate
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
        
        date = dateFormatter.date(from: expiredDate ?? "")
        
        let datePicker = UIDatePicker()
        datePicker.date = date ?? Date()
        datePicker.addTarget(self, action: #selector(datePickerDidChange(_:)), for: .valueChanged)
        datePicker.datePickerMode = .date
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
        
        expirationDateField.inputView = stackView
    }
    
    @objc func datePickerDoneButtonPressed(_ sender: Any) {
        let date = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        expirationDateField.text = dateFormatter.string(from: date)
        
        expirationDateField.resignFirstResponder()
    }
    
    @objc func datePickerDidChange(_ sender: UIDatePicker) {
        let date = sender.date
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        expirationDateField.text = dateFormatter.string(from: date)
    }
}
