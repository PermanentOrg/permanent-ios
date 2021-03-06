//  
//  RecordExifVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11/11/2020.
//

import Foundation

struct RecordExifVO: Model {
    let recordExifID, recordID, height, width: Int?
    let shutterSpeed, focalLength, aperture, fNumber: JSONAny? // TODO
    let exposure, iso, brightness: JSONAny? // TODO
    let flash: String?
    let whiteBalance, xdpi, ydpi: JSONAny? // TODO
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case recordExifID = "record_exifId"
        case recordID = "recordId"
        case height, width, shutterSpeed, focalLength, aperture, fNumber, exposure, iso, brightness, flash, whiteBalance, xdpi, ydpi, createdDT, updatedDT
    }
}
