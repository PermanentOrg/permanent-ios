//  
//  NotificationTableViewCell.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.01.2021.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet var notificationLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var typeImageView: UIImageView!
    
    var notification: Notification? {
        didSet {
            notificationLabel.text = notification?.message
            dateLabel.text = notification?.date
            typeImageView.image = notification?.type.icon
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    fileprivate func configureUI() {
        notificationLabel.textColor = .textPrimary
        notificationLabel.font = Text.style8.font
        dateLabel.textColor = .textPrimary
        dateLabel.font = Text.style12.font
    }
    
}
