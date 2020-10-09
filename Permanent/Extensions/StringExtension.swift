//
//  StringExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21/09/2020.
//

import Foundation

extension String {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    func localized(withComment comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

// MARK: - Validations

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,20}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }

    var isPhoneNumber: Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
}
