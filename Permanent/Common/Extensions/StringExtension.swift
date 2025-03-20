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
    
    var dateOnly: String {
        return String(self.prefix(while: { ($0 != "T") && ($0 != " ") }))
    }
    
    func pluralized() -> String {
        return self + "s"
    }
    
    func parenthesized() -> String {
        return "(" + self + ")"
    }
}

// MARK: - Validations

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[a-zA-Z0-9\\+\\.\\_%\\-\\+]{1,256}@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }

    var isPhoneNumber: Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
    
    var isUSPhoneNumber: Bool {
        let usPhoneRegex = "^\\(?([0-9]{3})\\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$"
        return NSPredicate(format: "SELF MATCHES %@", usPhoneRegex).evaluate(with: self)
    }
}
