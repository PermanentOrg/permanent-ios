//
//  EDTFInterval.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation

/// A date range. The two ends are independent: either may be a date, left open, or marked unknown.
struct EDTFInterval: Codable, Equatable {
    /// `open` emits a bare `/`; `unknown` emits `..`. The server treats them as different values.
    enum Endpoint: Codable, Equatable {
        case date(EDTFDateParts)
        case open
        case unknown

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let word = try? container.decode(String.self) {
                switch word {
                case "open":
                    self = .open

                case "unknown":
                    self = .unknown

                default:
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "unknown endpoint \(word)"
                    )
                }
                return
            }
            self = .date(try container.decode(EDTFDateParts.self))
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .open:
                try container.encode("open")

            case .unknown:
                try container.encode("unknown")

            case .date(let parts):
                try container.encode(parts)
            }
        }
    }

    var start: Endpoint
    var end: Endpoint
}
