//
//  DateUtils.swift
//  Permanent
//
//  Created by Adrian Creteanu on 27/10/2020.
//

import Foundation

open class DateUtils {
    class var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }

    class var fileTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-hhmmss"
        return formatter.string(from: Date())
    }
}
